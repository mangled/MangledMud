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
		end
		
		def connect_player(player_name, password)
		end
		
		
		def create_player(player_name, password)
		end
		
		def change_password(player, old_password, new_password)
		end
	
	
	end