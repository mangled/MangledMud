require 'socket'
require 'time'
require_relative 'constants'
require_relative 'db'
require_relative 'game'
require_relative 'player'
require_relative 'look'
require_relative 'phrasebook'

class Session
  # I don't think all these need to be visible now and I should try to remove them from being so
  attr_accessor :player_id, :last_time, :output_buffer

  def initialize(db, game, descriptor_details, connected_players, notifier)
    @db = db
    @game = game
    @descriptor_details = descriptor_details
    @connected_players = connected_players

    @player_id = nil
    @last_time = nil
    @output_prefix = nil
    @output_suffix = nil
    @output_buffer = []

    @player = TinyMud::Player.new(db, notifier)
    @look = TinyMud::Look.new(db, notifier)

    welcome_user()
  end

  def do_command(db, game, command)
      @last_time = Time.now()
      @output_buffer = []
      player_quit = false

      command.chomp!()
      case
        when (command.strip() == TinyMud::Phrasebook.lookup('quit-command'))
          player_quit()
          player_quit = true
        when (command.strip() == TinyMud::Phrasebook.lookup('who-command'))
          wrap_command(->() { dump_users() })
        when (command.start_with?(TinyMud::Phrasebook.lookup('prefix-command')))
          @output_prefix = command[TinyMud::Phrasebook.lookup('prefix-command').length + 1..-1]
        when (command.start_with?(TinyMud::Phrasebook.lookup('suffix-command')))
          @output_suffix = command[TinyMud::Phrasebook.lookup('suffix-command').length + 1..-1]
        else
          if @player_id
              wrap_command(->() { @game.process_command(@player_id, command) })
          else
              check_connect(command)
          end
      end

      player_quit
  end

  def queue(message)
    @output_buffer << normalize_line_endings_for_transmission(message)
  end

  def shutdown()
    queue(TinyMud::Phrasebook.lookup('shutdown-message'))
  end

private

  def check_connect(message)
      command, user, password = parse_connect(message)
      case
        when command.nil?
          welcome_user()
        when command.start_with?("co")
          connect_player(user, password)
        when command.start_with?("cr")
          create_player(user, password)
        else
          welcome_user()
      end
  end

  def welcome_user()
    queue(TinyMud::Phrasebook.lookup('welcome-message'))
  end

  def goodbye_user()
    queue(TinyMud::Phrasebook.lookup('leave-message'))
  end

  def connect_player(user, password)
      connected_player = @player.connect_player(user, password)
      if connected_player == TinyMud::NOTHING
          queue(TinyMud::Phrasebook.lookup('connect-fail'))
          puts "FAILED CONNECT #{user} on descriptor #{@descriptor_details}"
      else
          puts "CONNECTED #{@db[connected_player].name}(#{connected_player}) on descriptor #{@descriptor_details}"
          @player_id = connected_player
          @look.do_look_around(connected_player)
      end
  end

  def create_player(user, password)
    new_player = @player.create_player(user, password)
    if new_player == TinyMud::NOTHING
        queue(TinyMud::Phrasebook.lookup('create-fail'))
        puts "FAILED CREATE #{user} on descriptor #{@descriptor_details}"
    else
        puts "CREATED #{@db[new_player].name}(#{new_player}) on descriptor #{@descriptor_details}"
        @player_id = new_player
        @look.do_look_around(new_player)
    end
  end

  def player_quit()
    goodbye_user()
    if @player_id
      puts "DISCONNECTED #{@db[@player_id].name} #{@descriptor_details}"
    else
      puts "DISCONNECTED #{@descriptor_details}"
    end
  end

  # Do we need to expose @descriptors?
  def dump_users()
    now = Time.now()
    queue("Current Players:")
    connected_players = @connected_players.call()
    connected_players.each do |connected_player|
      if connected_player.last_time
        queue("#{@db[connected_player.player_id].name} idle #{(now - connected_player.last_time).to_i} seconds")
      else
        queue("#{@db[connected_player.player_id].name} idle forever")
      end
    end
  end

  def parse_connect(message)
      message.strip!
      match = /^([[:graph:]]+)\s+([[:graph:]]+)\s+([[:graph:]]+)/.match(message)
      match ? match[1..3] : []
  end

  def normalize_line_endings_for_transmission(s)
    s.chomp().gsub("\n", "\r\n") + "\r\n"
  end

  def wrap_command(command)
    queue(@output_prefix) if @output_prefix
    command.call()
    queue(@output_suffix) if @output_suffix
  end

end

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
    descriptor[1].queue(message) if descriptor
  end

  def run(db, game)
    while !game.shutdown
      res = select([@serverSocket] + @descriptors.keys, nil, @descriptors.keys, nil)
      if res
        # Errors
        res[2].each do |descriptor|
            remove(descriptor)
            $stderr.puts "socket had an error"
        end
        res[0].each do |descriptor|
          begin
            player_quit = false
            if descriptor == @serverSocket
              accept_new_connection(db, game)
            else
              unless descriptor_closed(db, descriptor)	  
                session = @descriptors[descriptor]
                player_quit = session.do_command(db, game, descriptor.gets())
              end
            end
            write_buffers()
            remove(descriptor) if player_quit
          rescue SystemCallError => e
            puts "ERROR READING SOCKET: #{e}"
            remove(descriptor)
          end
        end
      end
    end
    shutdown_sessions()
    write_buffers()
    close_sockets()
  end

  def descriptor_closed(db, descriptor)
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

  def shutdown_sessions()
    @descriptors.values.each {|session| session.shutdown() }
  end

  def close_sockets()
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

  def accept_new_connection(db, game)
    descriptor = @serverSocket.accept
    connected_players = ->() { @descriptors.values.find_all {|session| session.player_id } }
    @descriptors[descriptor] = Session.new(db, game, "#{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}", connected_players, self)
    puts "ACCEPT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    write_buffers()
  end

  def remove(descriptor)
    unless descriptor.closed?
        descriptor.flush
        descriptor.close
    end
    @descriptors.delete(descriptor)
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
