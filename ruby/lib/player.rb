#Port of Tinymud's player.c to Ruby.  See http://mangled.me/blog/coding/ruby-port-of-tinymud-wip/
#Author: Alexander Morrow
#Email:	 amo3@umbc.edu

require_relative '../test/include'
module TinyMud
	
	#Player class takes care of player's creation, access, and connection.
	class Player
		
		#Looks up a player by name, returns their index in the database.
		#Currently O(N) time, should be worked on after initial port is complete.
		def lookup_player(player_name)
			if(@db.length() == 0)
				return NOTHING
			end
			for i in (0..@db.length()-1)
				current_record = @db.get(i)
				#puts "Comparing name: #{current_record.name()} to #{player_name}"
				#puts "flags == TYPE_PLAYER? : #{current_record.flags == TYPE_PLAYER}"
				if(current_record.flags() == TYPE_PLAYER && current_record.name().upcase() == player_name.upcase())
					return i
				end
			end
			return NOTHING
		end
		
		#Checks to see if a player's name and password exists in the database.
		#If it does, returns that player's index.
		#Else, returns NOTHING
		def connect_player(player_name, password)
			
			player = lookup_player(player_name)
			
			if(player == NOTHING)
				return NOTHING
			elsif(@db.get(player).password == password)
				return player
			else
				return NOTHING
			end
		end
		
		
		#Creates a player with the given name.
		#Name must be valid and not in use.
		#Adds player to start room.
		def create_player(player_name, password)
			name_checker = Predicates.new(@db)
			
			#if(!name_checker.okay_player_name(player_name))
			if(name_checker.ok_player_name(player_name)==0)
				return NOTHING
			else
				player_index = @db.add_new_record()
				player = @db.get(player_index)
				
				player.name = player_name
				player.location = PLAYER_START
				player.exits = PLAYER_START
				player.owner = player_index
				player.flags = TYPE_PLAYER
				player.password = password
				
				#in DB.h #define PUSH(thing, locative) ((db[(thing)].next = (locative)), (locative) = (thing))
				#/* link him to PLAYER_START */
				#PUSH(player, db[PLAYER_START].contents);
				#Not sure if this line needs to be here...
				player.next = @db.get(PLAYER_START).contents
				@db.get(PLAYER_START).contents = player_index
				
				return player_index
			end
		end
		
		
		#Changes a player's password. Notifies an interface if the password changes or the passwords are not the same.
		def change_password(player_index, old_password, new_password)
			player = @db.get(player_index)
			if(old_password != player.password)
				#puts "Printing sorry because old pass(#{old_password}) != current pass(#{player.password})" 
				Interface.do_notify(player_index, "Sorry")
			elsif(old_password == player.password)
				player.password = new_password
				#puts "Printing changed because old pass(#{old_password}) == current pass(#{player.password})" 
				Interface.do_notify(player_index, "Password changed.")
			else
				#puts "not printing anything, neither are true."
			end
		end
		
		
		
		def initialize(db)
			@db = db
		end
	
	
	end
end