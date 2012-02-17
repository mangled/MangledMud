require_relative '../test/include'
require_relative './helpers.rb'

require 'gserver'

module TinyMud
class Interface < GServer
	include Helpers
	def initialize(*args)
	
		super(*args)
		
		@@db = Db.new()
		Db.Minimal()
		@@game = Game.new(@@db)
		@@connected_users = 0
		@@chat_queue = Queue.new()
		@@player_hash = {} 
		@player = Player.new(@@db)
		
	end
	
	#used to send commands from code back to players.
    def self.do_notify(player_index, message)
		chat_queue.push(NotifyMessage(player_index, message))
    end

	
	
	#This will run on connect.
	def serve(io)
		@@connected_users += 1
		current_connection = @@connected_users
		io.puts("Welcome to Ruby-TinyMUD.  Please login.  You are user #{@@connected_users}\n")
		io.puts ("Current list of objects that exist:")
		
		for i in (0..@@db.length()-1)
			io.puts(@@db.get(i).name)
		end
		
		io.puts("Username: ")
		player_name = io.gets.strip()
		player_index = @player.lookup_player(player_name)
		
		
		if(player_index == NOTHING)
			io.puts("You do not exist yet.  Creating character #{player_name}.  Disconnect to abort process.")
			io.puts("Password: ")
			password = io.gets().strip()
			#should double check here. later.
			player_index = @player.create_player(player_name, password)
			if(player_index == NOTHING)
				io.puts "#{player_index} Bad name. Reconnect to try again."
				
				#exit is not what I'm looking for.. quits the server. Need to find a way to end the connection only.
				exit()
			end
		else
		
			io.puts("Password: ")
			password = io.gets().strip()
			player_index = @player.connect_player(player_name, password)
			if(player_index == NOTHING)
				io.puts "That is the incorrect password. Goodbye."
				
				#exit is not what I'm looking for.. quits the server. Need to find a way to end the connection only.
				exit()
			end
		end
		
		#Add them to the hash of connected players.
		#Should test what happens if a player connects twice here...
		@@player_hash[player_index] = io
		@@player_hash[player_index].puts("This worked.")
		
		#User now finally connected to their account.  Begin processing commands.
		loop do
			
			line = io.gets.strip()
			io.puts("YOU SAID: #{line}")
			@@chat_queue.push(ActionMessage.new(player_index, line))
			io.puts("QUEUE SIZE: #{@@chat_queue.length}")
		
		end
		
    end
end


#used to add player notifications to queue.
class NotifyMessage
	@player_index
	@message
	
	def initialize(player_index, message)
		@player_index = player_index
		@message = message
	end
end

#Used to add player actions to queue.
class ActionMessage
	@player_index
	@message
	
	def initialize(player_index, message)
		@player_index = player_index
		@message = message
	end
	
end


server = Interface.new(2525)
server.start

while(true)
	if(Interface.chat_queue.length > 0)
		action = Interface.chat_queue.pop()
		
		puts("CLASS OF COMMAND = #{action.class()}")
		if(action.class() == "NotifyMessage")
			player_index = action.player_index
			message = action.message
			Interface.player_hash[player_index].puts(message)
		elsif(action.class() == "ActionMessage")
			player_index = action.player_index
			message = action.message
			Interface.Game.process_command(player_index,message)
		end
	end
end
server.shutdown

end
