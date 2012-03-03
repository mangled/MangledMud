# The "front end" to MangledMUD
require 'socket'
require 'time'
require_relative 'constants'
require_relative 'db'
require_relative 'game'
require_relative 'player'
require_relative 'look'
require_relative 'phrasebook'

require 'pp'

# *** THIS IS WIP AND YET TO BE REFACTORED ****
# It also needs to rescue itself from potential errors
# I can add some tests possibly to the interface tests
# e.g. send then disconnect. Possibly I will have to use
# raw sockets.

class MangledMUDServer

  # todo - move these out into the prasebook
  QUIT_COMMAND = "QUIT"
  WHO_COMMAND = "WHO"
  PREFIX_COMMAND = "OUTPUTPREFIX"
  SUFFIX_COMMAND = "OUTPUTSUFFIX"
  HELP_FILE = "help.txt"
  NEWS_FILE = "news.txt"

  def initialize(host, port)
    # todo - convert to an array
    @connect_details = Struct.new(:player, :last_time, :output_prefix, :output_suffix)
    # Use an array?
    @descriptors = Hash.new { |hash, key| hash[key] = @connect_details.new(nil) }
    @serverSocket = TCPServer.new(host, port)
    @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    puts "Server started at #{host} on port #{port}"
  end

  def do_notify(player_ref, s)
    player = @descriptors.find {|k, v| v[:player] == player_ref }
    # Because the db has no concept of a logged off player, messages can be sent
    # to players who are in a room etc. but not connected!
    notify(player[0], s) if player
  end

  def run(db, game)
    # todo: consider binding player to the descriptor
    player = TinyMud::Player.new(db, self)
    look = TinyMud::Look.new(db, self)

    while !game.shutdown
      # TIDY this, can pass in [@serverSocket] + , and just @desc into the 3rd arg, for other errors
      res = select([@serverSocket] + @descriptors.keys, nil, @descriptors.keys, nil)
      if res
        # Errors
        res[2].each do |sock|
            sock.close
            @descriptors.delete(sock)
            raise "socket had error" ##{sock.peeraddr.join(':')} 
        end
        # Iterate through the tagged read descriptors
        res[0].each do |sock|
          begin
            # Received a connect to the server (listening) socket
            if sock == @serverSocket then
              accept_new_connection()
            else
              # Received something on a client socket
              # Can hang with (Errno::ECONNRESET)
              if sock.eof?
                  p = @descriptors[sock][:player]
                  if p
                    puts "DISCONNECT #{sock.peeraddr[2]}:#{sock.peeraddr[1]} player #{db[p]}(#{p})"
                  else
                    puts "DISCONNECT descriptor #{sock.peeraddr[2]}:#{sock.peeraddr[1]} never connected"
                  end
                  sock.close
                  @descriptors.delete(sock)
              else
                  unless sock == @serverSocket
                    # Should this be gets? what if there are multiple strings?
                    # I think it will arrive as a single massive string - add a test for this case		  
                    @descriptors[sock][:last_time] = Time.now()
                    line = sock.gets()
                    do_command(db, game, player, look, sock, line)
                    break if game.shutdown()
                  end
              end
            end
          rescue Exception => e # Errno::'s catch specific
            puts "ERROR: #{e}"
            sock.close
            @descriptors.delete(sock)
          end
        end
      end
    end
    close_sockets()
  end

  def close_sockets()
    @descriptors.each do |d, v|
      notify(d, TinyMud::Phrasebook.lookup('shutdown-message'))
      d.flush
      d.close
    end
    @descriptors.clear()
  end

private

  def do_command(db, game, player, look, descriptor, command)
      command.chomp!()

      if (command.strip() == QUIT_COMMAND)
        goodbye_user(descriptor)
        player = @descriptors[descriptor][:player]
        if player
          puts "DISCONNECTED #{db[player].name} #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
        else
          puts "DISCONNECTED #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
        end
        # Yuk, here?
        descriptor.close
        @descriptors.delete(descriptor)
      elsif (command.strip() == WHO_COMMAND)
        # added these so we can sync. for tests, it seems reasonable though
        connection_details = @descriptors[descriptor]
        if connection_details[:output_prefix]
          notify(descriptor, connection_details[:output_prefix])
        end
        dump_users(db, descriptor)
        if connection_details[:output_suffix]
          notify(descriptor, connection_details[:output_suffix])
        end
      elsif (command.start_with?(PREFIX_COMMAND))
        @descriptors[descriptor][:output_prefix] = command[PREFIX_COMMAND.length + 1..-1]
      elsif (command.start_with?(SUFFIX_COMMAND))
        @descriptors[descriptor][:output_suffix] = command[SUFFIX_COMMAND.length + 1..-1]
      else
        connection_details = @descriptors[descriptor]
        if connection_details[:player]

            if connection_details[:output_prefix]
              notify(descriptor, connection_details[:output_prefix])
            end

            # Main game command processing
            game.process_command(connection_details[:player], command)

            if connection_details[:output_suffix]
              notify(descriptor, connection_details[:output_suffix])
            end
        else
            check_connect(db, player, look, descriptor, command)
        end
      end
  end

  def notify(descriptor, message)
    # All messages should go into a queue and send at end of processing
    raise "Arg" if descriptor == @serverSocket
    return unless @descriptors.keys.find {|d| d == descriptor }

    # We need a tidier way of doing this!!!
    # Errno::EPIPE
    begin
      descriptor.write(message.chomp().gsub("\n", "\r\n") + "\r\n")
    rescue Exception => e # Errno::'s catch specific
      puts "ERROR: #{e}"
      # Yuk, here?
      descriptor.close
      @descriptors.delete(descriptor)
    end
  end

  def dump_users(db, descriptor)
    now = Time.now()
    notify(descriptor, "Current Players:")
    @descriptors.each do |d, info|
      if d != @serverSocket # not needed now
        if info[:player]
          if info[:last_time]
            notify(descriptor, "#{db[info[:player]].name} idle #{(now - info[:last_time]).to_i} seconds")
          else
            notify(descriptor, "#{db[info[:player]].name} idle forever")
          end
        end
      end
    end
  end

  def accept_new_connection
    descriptor = @serverSocket.accept
    @descriptors[descriptor]
    puts "ACCEPT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    welcome_user(descriptor)
  end

  def welcome_user(descriptor)
    notify(descriptor, TinyMud::Phrasebook.lookup('welcome-message'))
  end

  def goodbye_user(descriptor)
    notify(descriptor, TinyMud::Phrasebook.lookup('leave-message'))
  end

  def check_connect(db, player, look, descriptor, message)
      command, user, password = parse_connect(message)

      if command.nil?
        welcome_user(descriptor)
        return
      end

      if command.start_with?("co")
        connected_player = player.connect_player(user, password)
        if connected_player == TinyMud::NOTHING
            notify(descriptor, TinyMud::Phrasebook.lookup('connect-fail'))
            puts "FAILED CONNECT #{user} on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
        else
            puts "CONNECTED #{db[connected_player].name}(#{connected_player}) on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}\n"
            @descriptors[descriptor][:player] = connected_player
            look.do_look_around(connected_player)
        end
      elsif command.start_with?("cr")
        new_player = player.create_player(user, password)
        if new_player == TinyMud::NOTHING
            notify(descriptor, TinyMud::Phrasebook.lookup('create-fail'))
            puts "FAILED CREATE #{user} on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
        else
            puts "CREATED #{db[new_player].name}(#{new_player}) on descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}\n"
            @descriptors[descriptor][:player] = new_player
            look.do_look_around(new_player)
        end
      else
        welcome_user(descriptor)
      end
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
    game = TinyMud::Game.new(db, dumpfile, server, lambda { server.close_sockets() })

    server.run(db, game)

    game.dump_database()

    exit(0)
end
