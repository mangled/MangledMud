require 'socket'
require 'time'
require_relative 'constants'
require_relative 'db'
require_relative 'game'
require_relative 'player'
require_relative 'look'
require_relative 'phrasebook'

# Wip - code will move from the server into this. I think its a better
# name than interface - which it will replace
class Session
  include Comparable

  attr_reader :descriptor
  attr_accessor :player_id, :last_time, :output_prefix, :output_suffix, :output_buffer

  def initialize()
    @descriptor = descriptor
    @player_id = nil
    @last_time = nil
    @output_prefix = nil
    @output_suffix = nil
    @output_buffer = []
  end

end

# *** THIS IS WIP AND YET TO BE REFACTORED ****
# *** THIS SHOULD MOVE INTO a Server.rb class *
class MangledMUDServer

  def initialize(host, port)
    # Use an array? Else WHO will return odd orders
    @descriptors = {}
    @serverSocket = TCPServer.new(host, port)
    @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    puts "Server started at #{host} on port #{port}"
  end

  def do_notify(player_id, message)
    descriptor = @descriptors.find {|descriptors, session| session.player_id == player_id }
    # Because the db has no concept of a logged off player, messages can be sent
    # to players who are in a room etc. but not connected!
    notify(descriptor[0], message) if descriptor
  end

  def run(db, game)
    # These will move into session.
    player = TinyMud::Player.new(db, self)
    look = TinyMud::Look.new(db, self)

    while !game.shutdown
      res = select([@serverSocket] + @descriptors.keys, nil, @descriptors.keys, nil)
      if res
        # Errors
        res[2].each do |sock|
            remove(sock)
            $stderr.puts "socket had an error"
        end
        res[0].each do |sock|
          begin
            if sock == @serverSocket
              accept_new_connection()
            else
              unless socket_closed(sock)	  
                @descriptors[sock].last_time = Time.now()
                @descriptors[sock].output_buffer = []
                session = @descriptors[sock]
                line = sock.gets()
                do_command(db, game, player, look, sock, session, line)
                write_buffers()
              end
            end
          rescue SystemCallError => e
            puts "ERROR READING SOCKET: #{e}"
            remove(sock)
          end
        end
      end
    end
    close_sockets()
  end

  def socket_closed(descriptor)
    if descriptor.eof?
      player_id = @descriptors[descriptor].player_id
      if player_id
        puts "DISCONNECT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]} player #{db[player_id]}(#{player_id})"
      else
        puts "DISCONNECT descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]} never connected"
      end
      remove(descriptor)
      return true
    end
    false
  end

  def close_sockets()
    @descriptors.keys.each do |descriptor|
      notify(descriptor, TinyMud::Phrasebook.lookup('shutdown-message'))
    end
    write_buffers()
    @descriptors.keys.each do |descriptor|
      begin
        unless descriptor.closed?
          descriptor.flush
          descriptor.close
        end
      rescue SystemCallError => e
        puts "ERROR CLOSING SOCKET: #{e}"
      end
    end
    @descriptors.clear()
  end

private

  def remove(descriptor)
    unless descriptor.closed?
        descriptor.flush
        descriptor.close
    end
    @descriptors.delete(descriptor)
  end

  def do_command(db, game, player, look, descriptor, session, command)
      command.chomp!()
      case
        when (command.strip() == TinyMud::Phrasebook.lookup('quit-command'))
          player_quit(db, descriptor)
        when (command.strip() == TinyMud::Phrasebook.lookup('who-command'))
          wrap_command(descriptor, ->() { dump_users(db, descriptor) })
        when (command.start_with?(TinyMud::Phrasebook.lookup('prefix-command')))
          session.output_prefix = command[TinyMud::Phrasebook.lookup('prefix-command').length + 1..-1]
        when (command.start_with?(TinyMud::Phrasebook.lookup('suffix-command')))
          session.output_suffix = command[TinyMud::Phrasebook.lookup('suffix-command').length + 1..-1]
        else
          if session.player_id
              wrap_command(descriptor, ->() { game.process_command(session.player_id, command) })
          else
              check_connect(db, player, look, descriptor, command)
          end
      end
  end

  def wrap_command(descriptor, command)
    connection_details = @descriptors[descriptor]
    notify(descriptor, connection_details.output_prefix) if connection_details.output_prefix
    command.call()
    notify(descriptor, connection_details.output_suffix) if connection_details.output_suffix
  end

  def player_quit(db, descriptor)
    goodbye_user(descriptor)
    player_id = @descriptors[descriptor].player_id
    if player_id
      puts "DISCONNECTED #{db[player_id].name} #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    else
      puts "DISCONNECTED #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    end
    remove(descriptor)
  end

  def write_buffers()
    @descriptors.each do |descriptor, session|
      begin
        buffer = session.output_buffer
        descriptor.write(buffer.join('')) if buffer.length > 0
        session.output_buffer = []
      rescue Exception => e
        puts "ERROR: #{e}"
        remove(descriptor)
      end
    end
  end

  def notify(descriptor, message)
    raise "You can't notify the server connection!" if descriptor == @serverSocket
    return unless @descriptors.keys.find {|d| d == descriptor }
    @descriptors[descriptor].output_buffer << normalize_line_endings_for_transmission(message)
  end

  def dump_users(db, descriptor)
    now = Time.now()
    notify(descriptor, "Current Players:")
    connected_players = @descriptors.values.find_all {|session| session.player_id }
    connected_players.each do |connected_player|
      if connected_player.last_time
        notify(descriptor, "#{db[connected_player.player_id].name} idle #{(now - connected_player.last_time).to_i} seconds")
      else
        notify(descriptor, "#{db[connected_player.player_id].name} idle forever")
      end
    end
  end

  def accept_new_connection
    descriptor = @serverSocket.accept
    @descriptors[descriptor] = Session.new()
    puts "ACCEPT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    welcome_user(descriptor)
    write_buffers()
  end

  def welcome_user(descriptor)
    notify(descriptor, TinyMud::Phrasebook.lookup('welcome-message'))
  end

  def goodbye_user(descriptor)
    notify(descriptor, TinyMud::Phrasebook.lookup('leave-message'))
    write_buffers()
  end

  def check_connect(db, player, look, descriptor, message)
      command, user, password = parse_connect(message)
      case
        when command.nil?
          welcome_user(descriptor)
        when command.start_with?("co")
          connect_player(db, player, look, descriptor, user, password)
        when command.start_with?("cr")
          create_player(db, player, look, descriptor, user, password)
        else
          welcome_user(descriptor)
      end
  end

  def create_player(db, player, look, descriptor, user, password)
    new_player = player.create_player(user, password)
    if new_player == TinyMud::NOTHING
        notify(descriptor, TinyMud::Phrasebook.lookup('create-fail'))
        puts "FAILED CREATE #{user} on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    else
        puts "CREATED #{db[new_player].name}(#{new_player}) on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}\n"
        @descriptors[descriptor].player_id = new_player
        look.do_look_around(new_player)
    end
  end

  def connect_player(db, player, look, descriptor, user, password)
      connected_player = player.connect_player(user, password)
      if connected_player == TinyMud::NOTHING
          notify(descriptor, TinyMud::Phrasebook.lookup('connect-fail'))
          puts "FAILED CONNECT #{user} on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
      else
          puts "CONNECTED #{db[connected_player].name}(#{connected_player}) on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}\n"
          @descriptors[descriptor].player_id = connected_player
          look.do_look_around(connected_player)
      end
  end

  def normalize_line_endings_for_transmission(s)
    s.chomp().gsub("\n", "\r\n") + "\r\n"
  end

  def parse_connect(message)
      message.strip!
      match = /^([[:graph:]]+)\s+([[:graph:]]+)\s+([[:graph:]]+)/.match(message)
      match ? match[1..3] : []
  end

end

# Main cmd line entry
if __FILE__ == $0
    if (ARGV.length < 2) or (ARGV.length > 3)
        puts "Usage: infile dumpfile [port]"
        exit(-1)
    end

    database, dumpfile, port = ARGV
    port = TinyMud::DEFAULT_PORT unless port

    db = TinyMud::Db.new()
    puts "LOADING: #{database}"
    db.load(database)
    puts "LOADING: #{database} (done)"

    # todo - this needs sorting out, its a little untidy
    # todo - assert dumpfile can be written to?
    server = MangledMUDServer.new("localhost", port)
    # todo - fix dependencies
    game = TinyMud::Game.new(db, dumpfile, "help.txt", "news.txt", server, lambda { server.close_sockets() })

    # todo - set the path for these files
    server.run(db, game)

    game.dump_database()

    exit(0)
end
