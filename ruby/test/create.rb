require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestCreate < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_do_open # Create an exit
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			record(bob) {|r| r.merge!( :location => NOTHING ) }
			
			create = TinyMud::Create.new
			notify = sequence('notify')

			# We must be somewhere (not NOTHING)
			Interface.expects(:do_notify).never.in_sequence(notify)
			create.do_open(bob, nil, nil)
			
			# Somewhere but don't specify what
			record(bob) {|r| r.merge!( :location => limbo ) }
			record(limbo) {|r| r.merge!( { :contents => wizard } ) }
			record(wizard) {|r| r.merge!({:next => bob})}
			Interface.expects(:do_notify).with(bob, "Open where?").in_sequence(notify)
			create.do_open(bob, nil, nil)
			
			# Bad exit name (all combinations tested in another class)
			Interface.expects(:do_notify).with(bob, "That's a strange name for an exit!").in_sequence(notify)
			create.do_open(bob, "me", nil)
			
			# Open onto something we don't control (limbo defaults this way)
			Interface.expects(:do_notify).with(bob, "Permission denied.").in_sequence(notify)
			create.do_open(bob, "exit", nil)
			
			# Own (controls) but too few pennies
			record(limbo) {|r| r.merge!( { :owner => bob } ) }
			Interface.expects(:do_notify).with(bob, "Sorry, you don't have enough pennies to open an exit.").in_sequence(notify)
			create.do_open(bob, "exit", nil)
			
			# Now have enough pennies
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			assert_equal(NOTHING, @db.get(limbo).exits)
			exit = @db.length
			create.do_open(bob, "exit", nil)
			assert_equal(exit, @db.get(limbo).exits)
			assert_equal(TYPE_EXIT, @db.get(exit).flags)
			assert_equal(bob, @db.get(exit).owner)
			assert_equal(NOTHING, @db.get(exit).location)
			
			# Now create an exit and link it to go somewhere (give invalid room address)
			place = @db.add_new_record
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			record(place) {|r| r.merge!({ :name => "place", :flags => TYPE_ROOM }) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "That's not a room!").in_sequence(notify)
			create.do_open(bob, "west", "place") # Note: Can have the same name (add a test)

			# Now with correct address, but do not own
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You can't link to that.").in_sequence(notify)
			create.do_open(bob, "west", "#{place}")

			# Now not enough pennies to link
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			record(place) {|r| r.merge!({ :owner => bob }) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You don't have enough pennies to link.").in_sequence(notify)
			create.do_open(bob, "west", "#{place}")

			# Now enough money
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			west = @db.length
			create.do_open(bob, "west", "#{place}")
			assert_equal(place, @db.get(west).location)
			
			# Now try "here" (we contol limbo at present)
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			south = @db.length
			create.do_open(bob, "south", "here")
			assert_equal(limbo, @db.get(south).location)

			# Now try "HOME"
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			north = @db.length
			create.do_open(bob, "north", "home")
			assert_equal(HOME, @db.get(north).location)
			
			# Now try another exit with the same name as before!
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, "Opened.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Trying to link...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			south = @db.length
			create.do_open(bob, "south", "here")
			assert_equal(limbo, @db.get(south).location)
		end
		
		def test_do_link # link player via an exit to a room that they own
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			place = @db.add_new_record
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }
			record(place) {|r| r.merge!({ :name => "place", :flags => TYPE_ROOM }) }

			create = TinyMud::Create.new
			notify = sequence('notify')

			# We must be somewhere (not NOTHING)
			record(bob) {|r| r.merge!( { :location => NOTHING, :next => NOTHING } ) }
			Interface.expects(:do_notify).never.in_sequence(notify)
			create.do_link(bob, nil, nil)
			
			# The room name must be parsable, "me", "home" or owned
			record(bob) {|r| r.merge!( { :location => limbo } ) }
			Interface.expects(:do_notify).with(bob, "That's not a room!").in_sequence(notify)
			create.do_link(bob, nil, "fig") # Not real!
			Interface.expects(:do_notify).with(bob, "You can't link to that.").in_sequence(notify)
			create.do_link(bob, nil, "#{place}") # Not owned
			
			# Now create an exit and move it about (matches in numerous locations!)
			# Not using the above as I want to control it step by step
			exit = @db.add_new_record
			record(place) {|r| r.merge!({ :owner => bob }) }
			record(exit) {|r| r.merge!( { :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING } ) }
			
			# Missing exit (exists but not here, note - not testing the match logic to the full, calls on, will mock in ruby)
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Exit in a location: link, own, but its in use
			record(limbo) {|r| r.merge!({ :exits => exit }) }
			Interface.expects(:do_notify).with(bob, "That exit is already linked.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			# Exit in a location: link, own, but its being carried
			record(exit) {|r| r.merge!({ :location => wizard }) }
			Interface.expects(:do_notify).with(bob, "That exit is being carried.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			# Exit in a location: link, don't own
			record(exit) {|r| r.merge!({ :owner => wizard }) }
			Interface.expects(:do_notify).with(bob, "Permission denied.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")

			# Exit not in a location: Ok, but poor, link to it, own it and its "free" (location is where it goes to)
			record(exit) {|r| r.merge!({ :owner => bob, :location => NOTHING }) }
			Interface.expects(:do_notify).with(bob, "It costs a penny to link this exit.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Rich enough now!
			record(bob) {|r| r.merge!({ :pennies => LINK_COST }) }
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			assert_equal(bob, @db.get(exit).owner)
			assert_equal(place, @db.get(exit).location)
			assert_equal(0, @db.get(bob).pennies)

			# Exit not in a location: Ok, but poor, link to it, *don't* own it and its "free" (location is where it goes to)
			record(exit) {|r| r.merge!({ :owner => wizard, :location => NOTHING }) }
			Interface.expects(:do_notify).with(bob, "It costs two pennies to link this exit.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Rich enough now!
			record(bob) {|r| r.merge!({ :pennies => LINK_COST + EXIT_COST }) }
			assert_equal(0, @db.get(wizard).pennies)
			Interface.expects(:do_notify).with(bob, "Linked.").in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			assert_equal(EXIT_COST, @db.get(wizard).pennies)
			assert_equal(0, @db.get(bob).pennies)
			assert_equal(bob, @db.get(exit).owner)
			assert_equal(place, @db.get(exit).location)

			# Now we try to link a player - Sets their home (must control them)
			Interface.expects(:do_notify).with(bob, "Permission denied.").in_sequence(notify)
			create.do_link(bob, "wizard", "HOME")
			
			# Can't set home to home!
			Interface.expects(:do_notify).with(bob, "Can't set home to home.").in_sequence(notify)
			create.do_link(bob, "bob", "HOME")
			
			# Set home
			Interface.expects(:do_notify).with(bob, "Home set.").in_sequence(notify)
			assert_equal(limbo, @db.get(bob).exits)
			create.do_link(bob, "bob", "#{place}")
			assert_equal(place, @db.get(bob).exits)

			# Now set a room's drop-to location (we must control the room)
			Interface.expects(:do_notify).with(bob, "Permission denied.").in_sequence(notify)
			create.do_link(bob, "here", "#{place}")

			# We own it now :-)
			record(limbo) {|r| r.merge!({ :owner => bob }) }
			Interface.expects(:do_notify).with(bob, "Dropto set.").in_sequence(notify)
			assert_equal(NOTHING, @db.get(limbo).location)
			create.do_link(bob, "here", "#{place}")
			assert_equal(place, @db.get(limbo).location)

			# Cause default to be hit!
			record(limbo) {|r| r.merge!({ :flags => 0xffff }) }
			Interface.expects(:do_notify).with(bob, "Internal error: weird object type.").in_sequence(notify)
			create.do_link(bob, "here", "#{place}")

			# Last of all a wizard can use absolute names for things
			record(limbo) {|r| r.merge!({ :owner => wizard, :exits => exit }) }
			record(exit) {|r| r.merge!({ :owner => bob, :exits => NOTHING, :location => NOTHING }) }
			Interface.expects(:do_notify).with(wizard, "Linked.").in_sequence(notify)
			create.do_link(wizard, "##{exit}", "#{place}")
			
			# And can do the same for players
			Interface.expects(:do_notify).with(wizard, "Home set.").in_sequence(notify)
			create.do_link(wizard, "##{bob}", "#{place}")
			
			# And can do the same for players
			Interface.expects(:do_notify).with(wizard, "Home set.").in_sequence(notify)
			create.do_link(wizard, "*bob", "#{place}")
		end

		def test_do_dig # Creates a room
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }

			create = TinyMud::Create.new
			notify = sequence('notify')
			
			# don't specify what you want to dig
			Interface.expects(:do_notify).with(bob, "Dig what?").in_sequence(notify)
			create.do_dig(bob, nil)
			
			# Bad name (only testing one case as underlying code will be tested elsewhere)
			Interface.expects(:do_notify).with(bob, "That's a silly name for a room!").in_sequence(notify)
			create.do_dig(bob, "me")
			
			# Not enough money!
			Interface.expects(:do_notify).with(bob, "Sorry, you don't have enough pennies to dig a room.").in_sequence(notify)
			create.do_dig(bob, "treehouse")
			
			# Go for it!
			record(bob) {|r| r[:pennies] = ROOM_COST }
			Interface.expects(:do_notify).with(bob, "treehouse created with room number 3.").in_sequence(notify)
			create.do_dig(bob, "treehouse")
			assert_equal(0, @db.get(bob).pennies)
			assert_equal("treehouse", @db.get(3).name)
			assert_equal(bob, @db.get(3).owner)
			assert_equal(TYPE_ROOM, @db.get(3).flags)
		end
		
		def test_do_create # creates an object
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			exit = @db.add_new_record
			record(exit) {|r| r.merge!( { :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING } ) }
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }
			record(bob) {|r| r.merge!({ :location => limbo, :exits => exit }) }

			create = TinyMud::Create.new
			notify = sequence('notify')
			
			# don't specify what you want to create
			Interface.expects(:do_notify).with(bob, "Create what?").in_sequence(notify)
			create.do_create(bob, nil, 0)
			
			# Bad name (only testing one case as underlying code will be tested elsewhere)
			Interface.expects(:do_notify).with(bob, "That's a silly name for a thing!").in_sequence(notify)
			create.do_create(bob, "me", 0)
			
			# Weird cheap :-)
			Interface.expects(:do_notify).with(bob, "You can't create an object for less than nothing!").in_sequence(notify)
			create.do_create(bob, "tree", -1)
			
			# Too cheap (< OBJECT_COST), not enough money on you
			Interface.expects(:do_notify).with(bob, "Sorry, you don't have enough pennies.").in_sequence(notify)
			create.do_create(bob, "tree", OBJECT_COST - 1)
			
			# Enough money (can't link here)
			record(bob) {|r| r[:pennies] = OBJECT_COST } # If an object is less than OBJECT_COST it will be set to it
			Interface.expects(:do_notify).with(bob, "Created.").in_sequence(notify)
			tree = @db.length
			create.do_create(bob, "tree", OBJECT_COST - 1)
			assert_equal("tree", @db.get(tree).name)
			assert_equal(bob, @db.get(tree).location)
			assert_equal(bob, @db.get(tree).owner)
			assert_equal((OBJECT_COST - 5) / 5, @db.get(tree).pennies)
			assert_equal(TYPE_THING, @db.get(tree).flags)
			# Objects home is here (limbo, can't link to, so home will be bob's home)
			assert_equal(exit, @db.get(tree).exits)
			assert_equal(tree, @db.get(bob).contents)
			
			# Enough money (can link here, cost is greater than MAX_OBJECT_ENDOWMENT)
			cost = ((MAX_OBJECT_ENDOWMENT + 1) * 5) + 5
			record(limbo) {|r| r.merge!({ :owner => bob }) }
			record(bob) {|r| r[:pennies] = cost }
			Interface.expects(:do_notify).with(bob, "Created.").in_sequence(notify)
			fish = @db.length
			create.do_create(bob, "fish", cost)
			assert_equal("fish", @db.get(fish).name)
			assert_equal(bob, @db.get(fish).location)
			assert_equal(bob, @db.get(fish).owner)
			assert_equal(MAX_OBJECT_ENDOWMENT, @db.get(fish).pennies)
			assert_equal(TYPE_THING, @db.get(fish).flags)
			assert_equal(limbo, @db.get(fish).exits)
			assert_equal(fish, @db.get(bob).contents)
		end

		# MOVE THIS SOMEWHERE - DRY
		def record(i)
			record = @db.get(i)

			args = {}
			args[:name] = record.name
			args[:description] = record.description
			args[:location] = record.location
			args[:contents] = record.contents
			args[:exits] = record.exits
			args[:next] = record.next
			args[:key] = record.key
			args[:fail] = record.fail
			args[:succ] = record.succ
			args[:ofail] = record.ofail
			args[:osucc] = record.osucc
			args[:owner] = record.owner
			args[:pennies] = record.pennies
			args[:flags] = record.flags
			args[:password] = record.password

			yield args

			args.each do |key, value|
				case key
				when :name
					record.name = value
				when :description
					record.description = value
				when :location
					record.location = value
				when :contents
					record.contents = value
				when :exits
					record.exits = value
				when :next
					record.next = value
				when :key
					record.key = value
				when :fail
					record.fail = value
				when :succ
					record.succ = value
				when :ofail
					record.ofail = value
				when :osucc
					record.osucc = value
				when :owner
					record.owner = value
				when :pennies
					record.pennies = value
				when :flags
					record.flags = value
				when :password
					record.password = value
				else
					raise("Record - unknown key #{key} with #{value}")
				end
			end

			@db.put(i, record)
		end
    end
end
