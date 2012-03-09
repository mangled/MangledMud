require_relative 'constants'

module TinyMud
	
	#Player class takes care of player's creation, access, and connection.
	class Player
		
		def initialize(db, notifier)
			@db = db
			@notifier = notifier
		end

		#Looks up a player by name, returns their index in the database.
		#Currently O(N) time, should be worked on after initial port is complete.
		def lookup_player(player_name)
			return NOTHING if (@db.length() == 0 or player_name.nil?)

			for i in (0..@db.length()-1)
				current_record = @db[i]
				if (((current_record.flags() & TYPE_MASK) == TYPE_PLAYER) && current_record.name && current_record.name().upcase() == player_name.upcase())
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
			elsif(@db[player].password == password)
				return player
			else
				return NOTHING
			end
		end
		
		#Creates a player with the given name.
		#Name must be valid and not in use.
		#Adds player to start room.
		def create_player(player_name, password)
			if (!Predicates.new(@db, @notifier).ok_player_name(player_name))
				return NOTHING
			else
				player_index = @db.add_new_record()
				player = @db[player_index]
				
				player.name = player_name
				player.location = PLAYER_START
				player.exits = PLAYER_START
				player.owner = player_index
				player.flags = TYPE_PLAYER
				player.password = password

				# link him to PLAYER_START 
				player.next = @db[PLAYER_START].contents
				@db[PLAYER_START].contents = player_index
				
				return player_index
			end
		end
		
		#Changes a player's password. Notifies an interface if the password changes or the passwords are not the same.
		def change_password(player_index, old_password, new_password)
			player = @db[player_index]
			if(old_password != player.password) 
				@notifier.do_notify(player_index, Phrasebook.lookup('sorry'))
			elsif(old_password == player.password)
				player.password = new_password
				@notifier.do_notify(player_index, Phrasebook.lookup('password-changed'))
			end
		end
	end
end
