require_relative 'helpers.rb'

module TinyMud
	class Create
		include Helpers
		
		def initialize(db)
			@db = db
			@pred = Predicates.new(db)
			@match = Match.new(db)
			
		end
		
		#Given a room name or special keyowrds "here" or "home", parse_linkable_room attempts to find the room
		#player is asking to link to, and return the index for the room it is associated with (or tell the player they can't).
		def parse_linkable_room(player, room_name)
			if(room_name.downcase == "here")
				room = @db[player].location
			elsif(room_name.downcase == "home")
				return HOME
			else
				room = Db.parse_dbref(room_name)
			end
			
			#Check room
			if((room < 0) || (room >= @db.length) || (typeof(room) != TYPE_ROOM))
				Interface.do_notify(player, "That's not a room!")
				return NOTHING
			elsif(!@pred.can_link_to(player, room))
				Interface.do_notify(player, "You can't link to that.")
				return NOTHING
			else
				return room
			end
		end
		
		#do_open opens an exit belonging to the player in the specified direction.
		#Player must be a builder or higher, must supply a valid exit, and must have enough pennies.
		def do_open(player,direction,linkto)
			loc = getloc(player)
			
			#Check to see if player is a builder.  Not in use, as restricted building is not currently being ported.
			#if(!is_builder(player))
			#	Interface.do_notify(player,"That command is restricted to authorized builders.")
			if(getloc(player) == NOTHING)
				return
			end
			if(direction == nil)
				Interface.do_notify(player, "Open where?")
				return
			elsif(!@pred.ok_name(direction))
				Interface.do_notify(player, "That's a strange name for an exit!")
				return
			end
			
			if(!@pred.controls(player,loc))
				Interface.do_notify(player, "Permission denied.")
			elsif(!@pred.payfor(player, EXIT_COST))
				Interface.do_notify(player, "Sorry, you don't have enough pennies to open an exit.")
			else
				exit = @db.add_new_record()
				room = @db[exit]
				room.name = direction
				room.owner = player
				room.flags = TYPE_EXIT
				
				#PUSH(exit, db[loc].exits)
				##define PUSH(thing, locative) \ ((db[(thing)].next = (locative)), (locative) = (thing))
				@db[exit].next = @db[loc].exits
				@db[loc].exits = exit
				
				Interface.do_notify(player, "Opened.")
				
				if(linkto != nil)
					Interface.do_notify(player, "Trying to link...")
					loc = parse_linkable_room(player, linkto)
					if(loc != NOTHING)
						if(!@pred.payfor(player, LINK_COST))
							Interface.do_notify(player, "You don't have enough pennies to link.")
						else
							#At this point all tests passed - Link the room.
							@db[exit].location = loc
							Interface.do_notify(player, "Linked.")
						end
					end
				end
			end
				
		end
		
		# Use this to link to a room that you own,
		# it seizes ownership of the exit.
		# costs 1 penny
		# plus a penny transferred to the exit owner if they aren't you.
		# you must own the linked-to room AND specify it by room number.
		def do_link(player, name, room_name)
			loc = getloc(player)
			return if (loc == NOTHING)

			room = parse_linkable_room(player, room_name)
			return if (room == NOTHING)

			@match.init_match(player, name, TYPE_EXIT)
			@match.match_exit()
			@match.match_neighbor()
			@match.match_possession()
			@match.match_me()
			@match.match_here()
			
			if (is_wizard(player)) 
				@match.match_absolute()
				@match.match_player()
			end
			
			thing = @match.noisy_match_result()		
			if (thing != NOTHING)
				case typeof(thing)
					when TYPE_EXIT
						#we're ok, check the usual stuff
						if(@db[thing].location != NOTHING)
							if(@pred.controls(player, thing))
								if(typeof(@db[thing].location) == TYPE_PLAYER)
									Interface.do_notify(player, "That exit is being carried.")
								else
									Interface.do_notify(player, "That exit is already linked.")
								end
							else
								Interface.do_notify(player, "Permission denied.")
							end
						else
							if(@db[thing].owner == player)
								if(!@pred.payfor(player, LINK_COST))
									Interface.do_notify(player, "It costs a penny to link this exit.")
									return
								end
							else
								if(!@pred.payfor(player, LINK_COST + EXIT_COST))
									Interface.do_notify(player, "It costs two pennies to link this exit.")
									return
								else
									#pay the owner for his loss
									@db[@db[thing].owner].pennies += EXIT_COST
								end
							end
						
							#link has been validated and paid for do it
							@db[thing].owner = player
							@db[thing].location = room
							
							#notify the player 
							Interface.do_notify(player, "Linked.")
						end
					when TYPE_THING
						if(!@pred.controls(player,thing))
							Interface.do_notify(player, "Permission denied.")
						elsif(room == HOME)
							Interface.do_notify(player, "Can't set home to home.")
						else
							#Activate link
							@db[thing].exits = room 
							Interface.do_notify(player, "Home set.")
						end
					when TYPE_PLAYER # todo: no drop-through in ruby, this is a copy of the above
						if(!@pred.controls(player,thing))
							Interface.do_notify(player, "Permission denied.")
						elsif(room == HOME)
							Interface.do_notify(player, "Can't set home to home.")
						else
							#Activate link
							@db[thing].exits = room 
							Interface.do_notify(player, "Home set.")
						end
					when TYPE_ROOM
						if(!@pred.controls(player,thing))
							Interface.do_notify(player, "Permission denied.")
						else
							@db[thing].location = room
							Interface.do_notify(player, "Dropto set.")
						end
					else #None of the types.	
						Interface.do_notify(player, "Internal error: weird object type.")
						$stderr.puts("PANIC weird object: typeof(thing) = #{typeof(thing)}\n")
				end
			end
		end
		
		#do_create creates an object with a particular name under the ownership of a player.
		#Creating an object costs penies.
		def do_create(player,name,cost)
			if(name == nil)
				Interface.do_notify(player, "Create what?")
				return
			elsif(!@pred.ok_name(name))
				Interface.do_notify(player, "That's a silly name for a thing!")
				return
			elsif(cost < 0)
				Interface.do_notify(player, "You can't create an object for less than nothing!")
				return
			elsif(cost < OBJECT_COST)
				cost = OBJECT_COST
			end
			
			
			
			if (!@pred.payfor(player, cost))
				Interface.do_notify(player, "Sorry, you don't have enough pennies.")
			else
				#Okay, create the object and initialize it.
				thing = @db.add_new_record()
				thing_record = @db[thing]
				
				thing_record.name = name
				thing_record.location = player
				thing_record.owner = player
				thing_record.pennies = endow(cost)
				thing_record.flags = TYPE_THING
				
				#Make sure endowment isn't higher than max.
				if(thing_record.pennies > MAX_OBJECT_ENDOWMENT)
					thing_record.pennies = MAX_OBJECT_ENDOWMENT
				end
				
				
				player_record = @db[player]
				if (player_record.location != NOTHING && @pred.can_link_to(player, player_record.location))
					thing_record.exits = player_record.location
				else
					thing_record.exits = player_record.exits
				end
				
				#PUSH(thing, db[player].contents)
				#define PUSH(thing, locative) \ ((db[(thing)].next = (locative)), (locative) = (thing))
				thing_record.next = player_record.contents
				player_record.contents = thing
				
				Interface.do_notify(player, "Created.")
			end
				
		end
		
		
		#Endow is a helper function to calculate the automatic endowment for an object. Originally in config.h.
		def endow(cost)
			return (cost - ENDOWMENT_CALCULATOR)/ENDOWMENT_CALCULATOR
		end
		
		
		#do_dig digs into an area, creating a new room.
		def do_dig(player,name)
			if(name == nil)
				Interface.do_notify(player, "Dig what?")
			elsif(!@pred.ok_name(name))
				Interface.do_notify(player, "That's a silly name for a room!")
			elsif(!@pred.payfor(player, ROOM_COST))
				Interface.do_notify(player, "Sorry, you don't have enough pennies to dig a room.")
			else
				#Everything is okay, create and initialize room
				room = @db.add_new_record()
				room_record = @db[room]
				
				
				room_record.name = name
				room_record.owner = player
				room_record.flags = TYPE_ROOM
				
				Interface.do_notify(player, "#{name} created with room number #{room}.")
			end
		end
	end
end
