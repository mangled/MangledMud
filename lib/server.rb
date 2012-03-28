require 'socket'
require 'thread'
require_relative 'constants.rb'
require_relative 'session'

# Provides a TCP based, telnet compatible server for running MangledMUD
#
# The command line entry point, defined in mud.rb configures this and
# the {MangledMud::Db} and {MangledMud::Game} instances.
#
# @version 1.0
class Server

  # Initialize the server to {#run} on a given host and port.
  #
  # @param [String] host machine
  # @param [Integer] port port
  def initialize(host, port)
    @descriptors = {}
    @serverSocket = TCPServer.new(host, port)
    @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    @db_semaphore = Mutex.new
  end

  # Run the main "game" loop.
  #
  # This method will start the server on the host and port specified in the initializer.
  # It handles new incomming connections, binding them to {MangledMud::Session}s, cleans up
  # disconnecting connections and runs a background thread to dump the database periodically.
  #
  # The method runs until an exiting signal occurs or a wizard shuts the game down.
  #
  # @see MangledMud::Dump
  # @param [MangledMud::Db] db the database instance to use
  # @param [MangledMud::Game] game the game instance to use
  def run(db, game)
    start_dump_thread(game)

    # Trap signals - Should probably add some more...
    trap("SIGINT") { emergency_shutdown(game) }

    # Main loop
    process_connections(db, game)

    # Shutdown
    Thread.kill(@dumper_thread)
    shutdown_sessions()
    write_buffers()
    close_sockets()
  end

  private

  # Wait for something to read, then process the returned IO objects
  def process_connections(db, game)
    while !game.shutdown
      res = select([@serverSocket] + @descriptors.keys, nil, nil, nil)
      res[0].each {|descriptor| process(db, game, descriptor) } if res
    end
  end

  # Handle a given IO descriptor. If its the main server socket, then open a new
  # connection, otherwise the descriptor is an existing connection, if so check
  # to see if its disconnected, else read something from it.
  def process(db, game, descriptor)
    begin
      player_quit = false
      if descriptor == @serverSocket
        accept_new_connection(db, game)
      else
        unless descriptor_closed(db, descriptor)
          session = @descriptors[descriptor]
          # Ensure that the dumper thread plays nice with the database
          @db_semaphore.synchronize {
            player_quit = session.do_command(descriptor.gets())
          }
        end
      end
      write_buffers()
      remove(descriptor) if player_quit
    rescue SystemCallError, IOError => e
      puts "ERROR READING SOCKET: #{e}"
      remove(descriptor)
    end
  end

  # The background thread periodically dumps the database.
  def start_dump_thread(game)
    @dumper_thread = Thread.new do
      sleep(MangledMud::DUMP_INTERVAL)
      @db_semaphore.synchronize {
        game.dump_database()
      }
      start_dump_thread(game)
    end
  end

  # Bind a new connection to a MangledMud::Session
  def accept_new_connection(db, game)
    descriptor = @serverSocket.accept
    connected_players = ->() { @descriptors.values.find_all {|session| session.player_id } }
    @descriptors[descriptor] = MangledMud::Session.new(db, game, "#{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}", connected_players)
    puts "ACCEPT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}"
    write_buffers()
  end

  # Get rid of a descriptor
  def remove(descriptor)
    unless descriptor.closed?
      descriptor.flush
      descriptor.close
    end
    @descriptors.delete(descriptor)
  end

  # For each descriptor's session, get its current output buffer and write it out
  def write_buffers()
    @descriptors.each do |descriptor, session|
      begin
        buffer = session.output_buffer
        descriptor.write(buffer.join('')) if buffer.length > 0
        session.output_buffer = []
      rescue SystemCallError, IOError => e
        puts "ERROR: #{e}"
        remove(descriptor)
      end
    end
  end

  # Check to see if a descriptor is closed
  def descriptor_closed(db, descriptor)
    if descriptor.eof?
      player_id = @descriptors[descriptor].player_id
      if player_id
        puts "DISCONNECT #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]} player #{db[player_id].name}(#{player_id})"
      else
        puts "DISCONNECT descriptor #{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]} never connected"
      end
      remove(descriptor)
      return true
    end
    false
  end

  # Close all connections...we are going down!
  def close_sockets()
    @descriptors.keys.each do |descriptor|
      begin
        unless descriptor.closed?
          descriptor.flush
          descriptor.close
        end
      rescue SystemCallError, IOError => e
        puts "ERROR CLOSING SOCKET: #{e}"
      end
    end
    @descriptors.clear()
  end

  # Notify all users that we are going to shutdown - Note, you still need to
  # write out buffers...
  def shutdown_sessions()
    @descriptors.values.each {|session| session.shutdown() }
  end

  # Something nasty has happened! Basically dump and abort.
  def emergency_shutdown(game)
    Thread.kill(@dumper_thread)
    Signal.list.each {|name, id| trap(name, "SIG_IGN") }
    close_sockets()
    game.panic("BAILOUT: caught signal")
    exit(-1)
  end

end
