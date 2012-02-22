require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'

module TinyMud
    class TestCreate < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = Db.Minimal()
		end

		def teardown
			@db.free()
		end
		
		def test_do_open # Create an exit
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			record(bob) {|r| r.merge!( :location => NOTHING ) }
			
			create = TinyMud::Create.new(@db)
			notify = sequence('notify')

			# We must be somewhere (not NOTHING)
			Interface.expects(:do_notify).never.in_sequence(notify)
			create.do_open(bob, nil, nil)
			
			# Somewhere but don't specify what
			record(bob) {|r| r.merge!( :location => limbo ) }
			record(limbo) {|r| r.merge!( { :contents => wizard } ) }
			record(wizard) {|r| r.merge!({:next => bob})}
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('open-where')).in_sequence(notify)
			create.do_open(bob, nil, nil)
			
			# Bad exit name (all combinations tested in another class)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('strange-exit-name')).in_sequence(notify)
			create.do_open(bob, "me", nil)
			
			# Open onto something we don't control (limbo defaults this way)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-permission')).in_sequence(notify)
			create.do_open(bob, "exit", nil)
			
			# Own (controls) but too few pennies
			record(limbo) {|r| r.merge!( { :owner => bob } ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-poor-open')).in_sequence(notify)
			create.do_open(bob, "exit", nil)
			
			# Now have enough pennies
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			assert_equal(NOTHING, @db[limbo].exits)
			exit = @db.length
			create.do_open(bob, "exit", nil)
			assert_equal(exit, @db[limbo].exits)
			assert_equal(TYPE_EXIT, @db[exit].flags)
			assert_equal(bob, @db[exit].owner)
			assert_equal(NOTHING, @db[exit].location)
			
			# Now create an exit and link it to go somewhere (give invalid room address)
			place = @db.add_new_record
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			record(place) {|r| r.merge!({ :name => "place", :flags => TYPE_ROOM }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('not-a-room')).in_sequence(notify)
			create.do_open(bob, "west", "place") # Note: Can have the same name (add a test)

			# Now with correct address, but do not own
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('bad-link')).in_sequence(notify)
			create.do_open(bob, "west", "#{place}")

			# Now not enough pennies to link
			record(bob) {|r| r.merge!( :pennies => EXIT_COST ) }
			record(place) {|r| r.merge!({ :owner => bob }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('too-poor-to-link')).in_sequence(notify)
			create.do_open(bob, "west", "#{place}")

			# Now enough money
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			west = @db.length
			create.do_open(bob, "west", "#{place}")
			assert_equal(place, @db[west].location)
			
			# Now try "here" (we contol limbo at present)
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			south = @db.length
			create.do_open(bob, "south", "here")
			assert_equal(limbo, @db[south].location)

			# Now try "HOME"
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			north = @db.length
			create.do_open(bob, "north", "home")
			assert_equal(HOME, @db[north].location)
			
			# Now try another exit with the same name as before!
			record(bob) {|r| r.merge!( :pennies => EXIT_COST + LINK_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('opened')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('trying-to-link')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			south = @db.length
			create.do_open(bob, "south", "here")
			assert_equal(limbo, @db[south].location)
		end
		
		def test_do_link # link player via an exit to a room that they own
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			place = @db.add_new_record
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }
			record(place) {|r| r.merge!({ :name => "place", :flags => TYPE_ROOM }) }

			create = TinyMud::Create.new(@db)
			notify = sequence('notify')

			# We must be somewhere (not NOTHING)
			record(bob) {|r| r.merge!( { :location => NOTHING, :next => NOTHING } ) }
			Interface.expects(:do_notify).never.in_sequence(notify)
			create.do_link(bob, nil, nil)
			
			# The room name must be parsable, "me", "home" or owned
			record(bob) {|r| r.merge!( { :location => limbo } ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('not-a-room')).in_sequence(notify)
			create.do_link(bob, nil, "fig") # Not real!
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('bad-link')).in_sequence(notify)
			create.do_link(bob, nil, "#{place}") # Not owned
			
			# Now create an exit and move it about (matches in numerous locations!)
			# Not using the above as I want to control it step by step
			exit = @db.add_new_record
			record(place) {|r| r.merge!({ :owner => bob }) }
			record(exit) {|r| r.merge!( { :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING } ) }
			
			# Missing exit (exists but not here, note - not testing the match logic to the full, calls on, will mock in ruby)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('dont-see-that')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Exit in a location: link, own, but its in use
			record(limbo) {|r| r.merge!({ :exits => exit }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('exit-already-linked')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			# Exit in a location: link, own, but its being carried
			record(exit) {|r| r.merge!({ :location => wizard }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('exit-being-carried')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			# Exit in a location: link, don't own
			record(exit) {|r| r.merge!({ :owner => wizard }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-permission')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")

			# Exit not in a location: Ok, but poor, link to it, own it and its "free" (location is where it goes to)
			record(exit) {|r| r.merge!({ :owner => bob, :location => NOTHING }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('cost-penny-exit')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Rich enough now!
			record(bob) {|r| r.merge!({ :pennies => LINK_COST }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			assert_equal(bob, @db[exit].owner)
			assert_equal(place, @db[exit].location)
			assert_equal(0, @db[bob].pennies)

			# Exit not in a location: Ok, but poor, link to it, *don't* own it and its "free" (location is where it goes to)
			record(exit) {|r| r.merge!({ :owner => wizard, :location => NOTHING }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('cost-two-exit')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			
			# Rich enough now!
			record(bob) {|r| r.merge!({ :pennies => LINK_COST + EXIT_COST }) }
			assert_equal(0, @db[wizard].pennies)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('linked')).in_sequence(notify)
			create.do_link(bob, "exit", "#{place}")
			assert_equal(EXIT_COST, @db[wizard].pennies)
			assert_equal(0, @db[bob].pennies)
			assert_equal(bob, @db[exit].owner)
			assert_equal(place, @db[exit].location)

			# Now we try to link a player - Sets their home (must control them)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-permission')).in_sequence(notify)
			create.do_link(bob, "wizard", "HOME")
			
			# Can't set home to home!
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-set-home')).in_sequence(notify)
			create.do_link(bob, "bob", "HOME")
			
			# Set home
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('home-set')).in_sequence(notify)
			assert_equal(limbo, @db[bob].exits)
			create.do_link(bob, "bob", "#{place}")
			assert_equal(place, @db[bob].exits)

			# Now set a room's drop-to location (we must control the room)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-permission')).in_sequence(notify)
			create.do_link(bob, "here", "#{place}")

			# We own it now :-)
			record(limbo) {|r| r.merge!({ :owner => bob }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('drop-to-set')).in_sequence(notify)
			assert_equal(NOTHING, @db[limbo].location)
			create.do_link(bob, "here", "#{place}")
			assert_equal(place, @db[limbo].location)

			# Cause default to be hit!
			record(limbo) {|r| r.merge!({ :flags => 0xffff }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('internal-error')).in_sequence(notify)
			create.do_link(bob, "here", "#{place}")

			# Last of all a wizard can use absolute names for things
			record(limbo) {|r| r.merge!({ :owner => wizard, :exits => exit }) }
			record(exit) {|r| r.merge!({ :owner => bob, :exits => NOTHING, :location => NOTHING }) }
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('linked')).in_sequence(notify)
			create.do_link(wizard, "##{exit}", "#{place}")
			
			# And can do the same for players
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('home-set')).in_sequence(notify)
			create.do_link(wizard, "##{bob}", "#{place}")
			
			# And can do the same for players
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('home-set')).in_sequence(notify)
			create.do_link(wizard, "*bob", "#{place}")
		end

		def test_do_dig # Creates a room
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }

			create = TinyMud::Create.new(@db)
			notify = sequence('notify')
			
			# don't specify what you want to dig
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('dig-what')).in_sequence(notify)
			create.do_dig(bob, nil)
			
			# Bad name (only testing one case as underlying code will be tested elsewhere)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('silly-room-name')).in_sequence(notify)
			create.do_dig(bob, "me")
			
			# Not enough money!
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-poor-dig')).in_sequence(notify)
			create.do_dig(bob, "treehouse")
			
			# Go for it!
			record(bob) {|r| r[:pennies] = ROOM_COST }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('created-room', "treehouse", 3)).in_sequence(notify)
			create.do_dig(bob, "treehouse")
			assert_equal(0, @db[bob].pennies)
			assert_equal("treehouse", @db[3].name)
			assert_equal(bob, @db[3].owner)
			assert_equal(TYPE_ROOM, @db[3].flags)
		end
		
		def test_do_create # creates an object
			# Note: RESTRICTED_BUILDING is not defined and will not be tested
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			exit = @db.add_new_record
			record(exit) {|r| r.merge!( { :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING } ) }
			record(limbo) {|r| r.merge!({ :name => "limbo", :contents => wizard, :owner => wizard, :flags => TYPE_ROOM }) }
			record(wizard) {|r| r.merge!({ :next => bob }) }
			record(bob) {|r| r.merge!({ :location => limbo, :exits => exit }) }

			create = TinyMud::Create.new(@db)
			notify = sequence('notify')
			
			# don't specify what you want to create
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('create-what')).in_sequence(notify)
			create.do_create(bob, nil, 0)
			
			# Bad name (only testing one case as underlying code will be tested elsewhere)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('silly-thing-name')).in_sequence(notify)
			create.do_create(bob, "me", 0)
			
			# Weird cheap :-)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('objects-must-have-a-value')).in_sequence(notify)
			create.do_create(bob, "tree", -1)
			
			# Too cheap (< OBJECT_COST), not enough money on you
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-poor')).in_sequence(notify)
			create.do_create(bob, "tree", OBJECT_COST - 1)
			
			# Enough money (can't link here)
			record(bob) {|r| r[:pennies] = OBJECT_COST } # If an object is less than OBJECT_COST it will be set to it
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('created')).in_sequence(notify)
			tree = @db.length
			create.do_create(bob, "tree", OBJECT_COST - 1)
			assert_equal("tree", @db[tree].name)
			assert_equal(bob, @db[tree].location)
			assert_equal(bob, @db[tree].owner)
			assert_equal((OBJECT_COST - 5) / 5, @db[tree].pennies)
			assert_equal(TYPE_THING, @db[tree].flags)
			# Objects home is here (limbo, can't link to, so home will be bob's home)
			assert_equal(exit, @db[tree].exits)
			assert_equal(tree, @db[bob].contents)
			
			# Enough money (can link here, cost is greater than MAX_OBJECT_ENDOWMENT)
			cost = ((MAX_OBJECT_ENDOWMENT + 1) * 5) + 5
			record(limbo) {|r| r.merge!({ :owner => bob }) }
			record(bob) {|r| r[:pennies] = cost }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('created')).in_sequence(notify)
			fish = @db.length
			create.do_create(bob, "fish", cost)
			assert_equal("fish", @db[fish].name)
			assert_equal(bob, @db[fish].location)
			assert_equal(bob, @db[fish].owner)
			assert_equal(MAX_OBJECT_ENDOWMENT, @db[fish].pennies)
			assert_equal(TYPE_THING, @db[fish].flags)
			assert_equal(limbo, @db[fish].exits)
			assert_equal(fish, @db[bob].contents)
		end
    end
end
