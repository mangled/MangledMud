require 'socket'
require_relative 'session'

# The server!
class Server

  def initialize(host, port)
    @descriptors = {}
    @serverSocket = TCPServer.new(host, port)
    @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
  end

  def do_notify(player_id, message)
    descriptor = @descriptors.find {|descriptors, session| session.player_id == player_id }
    # Because the db has no concept of a logged off player, messages can be sent
    # to players who are in a room etc. but not connected!
    descriptor[1].queue(message) if descriptor
  end

  def run(db, game)
    while !game.shutdown
      res = select([@serverSocket] + @descriptors.keys, nil, nil, nil)
      if res
        res[0].each do |descriptor|
          begin
            player_quit = false
            if descriptor == @serverSocket
              accept_new_connection(db, game)
            else
              unless descriptor_closed(db, descriptor)	  
                session = @descriptors[descriptor]
                player_quit = session.do_command(descriptor.gets())
              end
            end
            write_buffers()
            remove(descriptor) if player_quit
          rescue SystemCallError, IOError => e
            puts "ERROR READING SOCKET: #{e}"
            remove(descriptor)
          end
        end
      end
    end
    # Shutdown
    shutdown_sessions()
    write_buffers()
    close_sockets()
  end

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
      rescue SystemCallError, IOError => e
        puts "ERROR CLOSING SOCKET: #{e}"
      end
    end
    @descriptors.clear()
  end

private

  def accept_new_connection(db, game)
    descriptor = @serverSocket.accept
    connected_players = ->() { @descriptors.values.find_all {|session| session.player_id } }
    @descriptors[descriptor] = MangledMud::Session.new(db, game, "#{descriptor.peeraddr[2]}:#{descriptor.peeraddr[1]}", connected_players, self)
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
      rescue SystemCallError, IOError => e
        puts "ERROR: #{e}"
        remove(descriptor)
      end
    end
  end

end