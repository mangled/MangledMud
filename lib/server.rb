require 'eventmachine'
require_relative 'constants.rb'
require_relative 'session'

module MangledMud

  # Provides a TCP based, telnet compatible server for running MangledMUD
  #
  # The command line entry point, defined in mud.rb configures this and
  # the {MangledMud::Db} and {MangledMud::Game} instances.
  #
  # @version 1.0
  class Server
    # @return [Array of Connections] Internal to this, not intended for public usage
    attr_accessor :connections
  
    # @param [String] host the host name of the machine the server will run on
    # @param [Number] port the port number to run on
    # @param [Db] db the database instance to use
    # @param [Game] game the game instance to use
    def initialize(host, port, db, game)
      @host = host
      @port = port
      @db = db
      @game = game
      @connections = []
    end
  
    # Start the server!
    def start
      EventMachine.add_periodic_timer(MangledMud::DUMP_INTERVAL) { @game.dump_database() }
      @signature = EventMachine.start_server(@host, @port, Connection, @db, @game) do |connection|
        connection.server = self
        @connections << connection
      end
    end

    # Stop the server
    def stop
      EventMachine.stop_server(@signature)
      @connections.each {|connection| connection.shutdown }
      unless wait_for_connections_and_stop
        EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
      end
    end

    # Write all output buffers to their connections
    def write_buffers()
      @connections.each {|connection| connection.write_buffer() }
    end

    # Get all the current sessions
    # @return [Array of Session]
    def sessions
      @connections.collect {|connection| connection.session }
    end

    private

    # Helper - If all connections are closed then stop the server
    def wait_for_connections_and_stop
      if @connections.empty?
        EventMachine.stop
        true
      else
        puts "Waiting for #{@connections.size} connection(s) to finish ..."
        false
      end
    end
  end
  
  # Internal class - Handles a connection to a player
  class Connection < EventMachine::Connection
    attr_accessor :server
    attr_accessor :session
  
    def initialize(db, game)
      connected_players = ->() { server.sessions.find_all {|sessions| sessions.player_id } }
      @game = game
      @session = MangledMud::Session.new(db, game, "foo", connected_players)
    end
  
    def post_init
      puts "Accepting a new connection"
      write_buffer()
    end
  
    def receive_data data
      unless @game.shutdown
        @session.queue_input(data)
  
        # Note: We handle all the commands issued by the player. If they send
        # tons of them then it will cause other players to be jammed. It's
        # not worth the code pain to fix this edge case, esp. for release 1.0
        # we do not expect people to be spamming the server in this way.
        remaining_commands, player_quit = @session.process_input()
        while (!player_quit and remaining_commands != 0)
          remaining_commands, player_quit = @session.process_input()
        end
  
        server.write_buffers()
  
        if @game.shutdown
          server.stop
        elsif player_quit
          close_connection_after_writing()
        end
      end
    end
  
    def shutdown
      @session.shutdown()
      write_buffer()
      close_connection_after_writing()
    end
  
    def unbind
      server.connections.delete(self)
    end
  
    def write_buffer()
      buffer = @session.output_buffer
      send_data(buffer.join('')) if buffer.length > 0
      @session.output_buffer = []
    end
  end
end
