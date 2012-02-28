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

class MangledMUDServer

  # todo - move these out
  QUIT_COMMAND = "QUIT"
  WHO_COMMAND = "WHO"
  PREFIX_COMMAND = "OUTPUTPREFIX"
  SUFFIX_COMMAND = "OUTPUTSUFFIX"
  HELP_FILE = "help.txt"
  NEWS_FILE = "news.txt"

  def initialize(host, port)
    @connect_details = Struct.new(:player, :last_time, :output_prefix, :output_suffix)
    @descriptors = Hash.new { |hash, key| hash[key] = @connect_details.new(nil) }
    @serverSocket = TCPServer.new(host, port)
    @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    @descriptors[@serverSocket]
    puts "Server started at #{host} on port #{port}"
  end

  def do_notify(player_ref, s)
    player = @descriptors.find {|k, v| v[:player] == player_ref }
    notify(player[0], s) if player
  end

  def run(db, game)
    # todo: consider binding player to the descriptor
    player = TinyMud::Player.new(db, self)
    look = TinyMud::Look.new(db, self)

    while true # This would break on interrupt - signals.
      res = select(@descriptors.keys, nil, nil, nil)
      if res
        # Iterate through the tagged read descriptors
        res[0].each do |sock|
          # Received a connect to the server (listening) socket
          if sock == @serverSocket then
            accept_new_connection()
          else
            # Received something on a client socket
            if sock.eof?
                player = @descriptors[sock][:player]
                if player
                  puts "DISCONNECT #{sock.peeraddr[2]}:#{sock.peeraddr[1]} player #{db[player]}(#{player})"
                else
                  puts "DISCONNECT descriptor #{sock.peeraddr[2]}:#{sock.peeraddr[1]} never connected"
                end
                sock.close
                @descriptors.delete(sock)
            else
                # Should this be gets? what if there are multiple strings?
                @descriptors[sock][:last_time] = Time.now()
                do_command(db, game, player, look, sock, sock.gets())
            end
          end
        end
      end
    end
  end

private

  def do_command(db, game, player, look, descriptor, command)
      command.chomp!()

      if (command.strip() == QUIT_COMMAND)
        goodbye_user(descriptor)
        # Yuk, here?
        descriptor.close
        @descriptors.delete(descriptor)
        0
      elsif (command.strip() == WHO_COMMAND)
        dump_users(db, descriptor)
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
      1
  end

  def notify(descriptor, message)
    raise "Arg" if descriptor == @serverSocket
    descriptor.puts(message)
  end

  def dump_users(db, descriptor)
    now = Time.now()
    notify(descriptor, "Current Players:")
    @descriptors.each do |d, info|
      if d != @serverSocket
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
    server = MangledMUDServer.new("localhost", port)
    server.run(db, TinyMud::Game.new(db, dumpfile, server))

    exit(0)
end
