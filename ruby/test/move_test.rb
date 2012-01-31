require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require_relative 'helpers'
require 'pp'

module TinyMud
    class TestMove < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = TinyMud::Db.new()
		end

		def teardown
			@db.free()
		end
		
		def test_moveto
			Db.Minimal()
			wizard = 1
			somewhere = @db.add_new_record
			record(somewhere) {|r| r[:contents] = NOTHING }
			bob = Player.new(@db).create_player("bob", "pwd")
		
			move = TinyMud::Move.new(@db)
			# bob is in nothing and is going to be moved to "0"
			record(bob) {|r| r[:location] = NOTHING }
			record(0) {|r| r[:contents] = NOTHING }
			move.moveto(bob, 0)
			assert_equal(bob, @db.get(0).contents)
			assert_equal(0, @db.get(bob).location)
			
			# bob is already somewhere!
			record(0) {|r| r[:contents] = NOTHING }
			record(bob) {|r| r[:location] = somewhere }
			record(somewhere) {|r| r[:contents] = bob }
			move.moveto(bob, 0)
			assert_equal(bob, @db.get(0).contents)
			assert_equal(0, @db.get(bob).location)
			assert_equal(NOTHING, @db.get(somewhere).contents)
		
			# move to nothing
			record(bob) {|r| r[:location] = somewhere }
			record(somewhere) {|r| r[:contents] = bob }
			move.moveto(bob, NOTHING)
			assert_equal(NOTHING, @db.get(bob).location)
			assert_equal(NOTHING, @db.get(somewhere).contents)
			
			# move home (for things and players exits point home)
			record(bob) {|r| r[:location] = somewhere }
			record(bob) {|r| r[:exits] = 0 }
			record(somewhere) {|r| r[:contents] = bob }
			move.moveto(bob, HOME)
			assert_equal(0, @db.get(bob).location)
			assert_equal(NOTHING, @db.get(somewhere).contents)
		
			# Check that code moves an item out of a contents list
			thing = @db.add_new_record
			record(somewhere) {|r| r[:contents] = thing }
			record(thing) {|r| r.merge!({ :flags => TYPE_THING, :location => somewhere, :next => bob }) }
			record(bob) {|r| r.merge!({ :location => somewhere, :next => NOTHING }) }
			record(0) {|r| r[:contents] = NOTHING }
			move.moveto(bob, 0)
			assert_equal(0, @db.get(bob).location)
			assert_equal(thing, @db.get(somewhere).contents)
			assert_equal(NOTHING, @db.get(thing).next)
		end
		
		def test_enter_room
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pod")
			jim = Player.new(@db).create_player("jim", "pds")
			start_loc = @db.add_new_record
			place = @db.add_new_record
		
			move = TinyMud::Move.new(@db)
		
			# Move to same location
			set_up_objects(start_loc, bob, anne, jim, place)
		
			notify = sequence('notify')
			Interface.expects(:do_notify).with(bob, 'somewhere').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, 'Contents:').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, 'anne').in_sequence(notify)
			move.enter_room(bob, start_loc)
		
			# Move "HOME"
			set_up_objects(start_loc, bob, anne, jim, place)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(anne, "bob has left.").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).description).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, 'bob is briefly visible through the mist.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
		
			move.enter_room(bob, HOME)
			
			# Move somewhere - not home
			set_up_objects(start_loc, bob, anne, jim, place)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(anne, "bob has left.").in_sequence(notify)
			Interface.expects(:do_notify).with(jim, "bob has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob ping').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			move.enter_room(bob, place)
			
			# Dark player - People in leaving room shouldn't see
			set_up_objects(start_loc, bob, anne, jim, place)
			record(bob) {|r| r[:flags] = r[:flags] | DARK }
			notify = sequence('notify')
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob ping').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			move.enter_room(bob, place)
			
			# Dark exit
			set_up_objects(start_loc, bob, anne, jim, place)
			record(start_loc) {|r| r[:flags] = r[:flags] | DARK }
			Interface.expects(:do_notify).with(jim, "bob has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob ping').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			move.enter_room(bob, place)
			
			# Move where there are only objects in the leaving location and STICKY is
			# set - The objects should move to the rooms location value
			set_up_objects(start_loc, bob, anne, jim, place)
			cheese = @db.add_new_record
			record(bob) {|r| r[:next] = cheese } # Remove anne from contents, only bob and an object
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :location => start_loc, :next => NOTHING }) }
			record(start_loc) {|r| r.merge!({ :flags => r[:flags] | STICKY, :location => place }) } # STICKY set to place
			assert_equal(start_loc, @db.get(cheese).location)
			Interface.expects(:do_notify).with(jim, "bob has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob ping').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			move.enter_room(bob, place)
			assert_equal(place, @db.get(cheese).location)
			
			# Now trigger a penny event by mocking the default behaviour
			set_up_objects(start_loc, bob, anne, jim, place)
			Move.expects(:get_penny_check).returns(1)
			Interface.expects(:do_notify).with(anne, "bob has left.").in_sequence(notify)
			Interface.expects(:do_notify).with(jim, "bob has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob ping').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You found a penny!").in_sequence(notify)
			move.enter_room(bob, place)
		end
		
		def test_send_home
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pod")
			cheese = @db.add_new_record
			egg = @db.add_new_record
			tomato = @db.add_new_record
			exit = @db.add_new_record
			place = @db.add_new_record
		
			move = TinyMud::Move.new(@db)
			record(limbo) {|r| r.merge!( :contents => anne ) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM, :next => NOTHING }) }
			record(anne) {|r| r.merge!({ :location => limbo, :exits => place, :flags => TYPE_PLAYER, :next => NOTHING, :contents => NOTHING }) }
			record(bob) {|r| r.merge!({ :location => place, :exits => limbo, :flags => TYPE_PLAYER, :next => NOTHING, :contents => cheese }) } # Home is at limbo
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING & STICKY, :location => bob, :owner => bob, :next => egg, :exits => place }) }
			record(egg) {|r| r.merge!({ :name => "egg", :description => "oval", :flags => TYPE_THING, :location => bob, :owner => bob, :next => tomato, :exits => place }) }
			record(tomato) {|r| r.merge!({ :name => "tomato", :description => "red", :flags => TYPE_THING, :location => bob, :owner => bob, :next => exit, :exits => limbo }) }
			record(exit) {|r| r.merge!({ :name => "exit", :description => "exit", :flags => TYPE_EXIT, :location => bob, :owner => bob, :next => NOTHING, :exits => place }) }
		
			# Send bob home (note it hangs!!! if only the wizard is in limbo - possibly limbo can't be home)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(anne, 'bob has arrived.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).description).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, 'bob is briefly visible through the mist.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "tomato(#6)").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			move.send_home(bob)
			assert_equal(limbo, @db.get(bob).location)
			assert_equal(bob, @db.get(cheese).location)
			assert_equal(place, @db.get(egg).location)
			assert_equal(bob, @db.get(exit).location)
			assert_equal(bob, @db.get(cheese).owner)
			assert_equal(cheese, @db.get(bob).contents)
		
			# Send a thing home - Funny how the people don't see the cheese arriving!
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :location => place, :owner => bob, :next => NOTHING, :exits => limbo }) }
			assert_equal(place, @db.get(cheese).location)
			move.send_home(cheese)
			assert_equal(limbo, @db.get(cheese).location)
		
			# Send a room! Nothing should happen
			Interface.expects(:do_notify).never
			move.send_home(place)
		end
		
		def test_can_move
			# Going home should always work (no db etc. needed to test)
			move = TinyMud::Move.new(@db)
			assert_equal(1, move.can_move(0, "home"))
			
			# Check players directions
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pod")
			place = @db.add_new_record
			exit = @db.add_new_record
		
			# First no exits
			record(bob) {|r| r[:exits] = NOTHING}
			assert_equal(0, move.can_move(bob, "east"))
			
			# General test (note it really pulls on match so limited testing is needed here)
			record(place) {|r| r.merge!({:name => "some place", :description => "yellow", :flags => TYPE_ROOM, :exits => exit, :next => NOTHING }) }
			record(exit) {|r| r.merge!( :name => "an exit;thing", :location => place, :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			record(bob) {|r| r[:exits] = exit }
			assert_equal(1, move.can_move(bob, "an exit"))
			assert_equal(0, move.can_move(bob, "an"))
			assert_equal(1, move.can_move(bob, "thing"))
			
			# Test absolute
			assert_equal(0, move.can_move(bob, "##{exit}"))
			record(exit) {|r| r[:owner] = bob }
			assert_equal(1, move.can_move(bob, "##{exit}"))
			
			# Non-owning exit
			record(exit) {|r| r[:name] = "an exit" }
			record(exit) {|r| r.merge!( :owner => anne ) }
			assert_equal(1, move.can_move(bob, "an exit"))
		end
		
		def test_do_move
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pod")
			jim = Player.new(@db).create_player("jim", "pds")
			start_loc = @db.add_new_record
			place = @db.add_new_record
			cheese = @db.add_new_record

			move = TinyMud::Move.new(@db)

			# Move to same location
			set_up_objects(start_loc, bob, anne, jim, place)
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :location => bob, :owner => bob, :next => NOTHING, :exits => place }) }
			record(bob) {|r| r[:contents] = cheese }

			# Move bob home (cheese went home too - different home)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(anne, 'bob goes home.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "There's no place like home...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "There's no place like home...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "There's no place like home...").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You wake up back home, without your possessions.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, 'bob has left.').in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, 'bob has arrived.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).description).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, 'bob is briefly visible through the mist.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			move.do_move(bob, "home")
			assert_equal(place, @db.get(cheese).location)
			assert_equal(bob, @db.get(cheese).owner)
			assert_equal(NOTHING, @db.get(bob).contents)
			
			# Normal move checks
			set_up_objects(start_loc, bob, anne, jim, place)
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r[:contents] = cheese }

			# Made up/non-existant exit
			Interface.expects(:do_notify).with(bob, "You can't go that way.").in_sequence(notify)
			move.do_move(bob, "tree house")
			
			# Ambiguous exit - I could not reproduce this, rationalized it was a bug! So fixed the original code (I hope :-))
			exits = @db.add_new_record
			exitw = @db.add_new_record
			record(exits) {|r| r.merge!( :location => place, :name => "exits", :description => "south", :flags => TYPE_EXIT, :next => exitw ) }
			record(exitw) {|r| r.merge!( :location => place, :name => "exitw", :description => "south east", :flags => TYPE_EXIT, :next => NOTHING ) }
			record(start_loc) {|r| r[:exits] = exits }
			Interface.expects(:do_notify).with(bob, "I don't know which way you mean!").in_sequence(notify)
			move.do_move(bob, "exit")

			# "Normal" - The exits location is where it goes.
			record(exits) {|r| r.merge!( :location => place, :name => "exits;jam", :description => "long", :flags => TYPE_EXIT, :next => exitw ) }
			record(exitw) {|r| r.merge!( :location => place, :name => "exitw", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			record(start_loc) {|r| r[:exits] = exits }
			
			Interface.expects(:do_notify).with(anne, 'bob has left.').in_sequence(notify)
			Interface.expects(:do_notify).with(jim, 'bob has arrived.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(jim, "bob " + @db.get(place).osucc).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "slim jim").in_sequence(notify)
			move.do_move(bob, "jam")
			assert_equal(place, @db.get(bob).location)
			assert_equal(cheese, @db.get(bob).contents)
			assert_equal(place, @db.get(cheese).location)
		end
		
		def test_do_get
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			cake = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			cheese = @db.add_new_record
			exit = @db.add_new_record
			exit2 = @db.add_new_record
			record(wizard) {|r| r.merge!({ :contents => cake }) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(cake) {|r| r.merge!({:name => "cake", :location => wizard, :description => "creamy", :osucc => "pong", :contents => NOTHING, :flags => TYPE_THING, :exits => NOTHING }) }
			record(exit2) {|r| r.merge!( :location => NOTHING, :name => "exit2", :description => "long2", :flags => TYPE_EXIT, :owner => NOTHING, :next => NOTHING ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => NOTHING ) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => wizard, :next => NOTHING ) }
			
			move = TinyMud::Move.new(@db)
			notify = sequence('notify')

			# Pick up a person
			Interface.expects(:do_notify).with(wizard, "You can't take that!").in_sequence(notify)
			move.do_get(wizard, "##{place}")
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			move.do_get(bob, "place")

			# Pick up something you are already carrying - Only a wizard can generate this message
			Interface.expects(:do_notify).with(wizard, "You already have that!").in_sequence(notify)
			move.do_get(wizard, "##{cake}")
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			move.do_get(bob, "cheese")

			# Pick up an exit in another room (not linked) - HAS to be in a location of NOTHING! WEIRD!
			Interface.expects(:do_notify).with(wizard, "You can't pick up an exit from another room.").in_sequence(notify)
			move.do_get(wizard, "##{exit2}")
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			move.do_get(bob, "exit2")

			# Try to pick up non-existant something
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			move.do_get(bob, "bread")
			
			# Try to pick up an exit (don't own)
			Interface.expects(:do_notify).with(bob, "You can't pick that up.").in_sequence(notify)
			move.do_get(bob, "exit")
			
			# Try to pick up a linked exit
			record(exit) {|r| r[:owner] = bob }
			Interface.expects(:do_notify).with(bob, "You can't pick up a linked exit.").in_sequence(notify)
			move.do_get(bob, "exit")
			
			# Unlink the exit i.e. still in room but not end location specified
			record(exit) {|r| r[:location] = NOTHING }
			Interface.expects(:do_notify).with(bob, "Exit taken.").in_sequence(notify)
			assert_equal(cheese, @db.get(bob).contents)
			assert_equal(exit, @db.get(place).exits)
			move.do_get(bob, "exit")
			assert_equal(NOTHING, @db.get(place).exits)
			assert_equal(exit, @db.get(bob).contents)
			assert_equal(bob, @db.get(exit).location)
			assert_equal(cheese, @db.get(exit).next)
			
			# Absolute should work on an exit
			record(bob) {|r| r.merge!( { :contents => cheese } ) }
			record(exit) {|r| r.merge!( :location => NOTHING, :next => NOTHING )}
			record(place) {|r| r[:exits] = exit }
			Interface.expects(:do_notify).with(bob, "Exit taken.").in_sequence(notify)
			move.do_get(bob, "##{exit}")
			assert_equal(NOTHING, @db.get(place).exits)
			assert_equal(exit, @db.get(bob).contents)
			assert_equal(bob, @db.get(exit).location)
			assert_equal(cheese, @db.get(exit).next)
			
			# Drop the cheese and try to take it
			record(exit) {|r| r[:next] = NOTHING }
			record(cheese) {|r| r[:location] = place }
			record(bob) {|r| r[:next] = cheese } # Room content list
			Interface.expects(:do_notify).with(bob, "Taken.").in_sequence(notify)
			move.do_get(bob, "cheese")
			assert_equal(NOTHING, @db.get(bob).next)
			assert_equal(cheese, @db.get(bob).contents)
			assert_equal(exit, @db.get(cheese).next)
			
			# Again with absolute
			record(exit) {|r| r[:next] = NOTHING }
			record(cheese) {|r| r.merge!({ :location => place, :next => NOTHING }) }
			record(bob) {|r| r.merge!({ :next => cheese, :contents => exit }) } # Room content list
			Interface.expects(:do_notify).with(bob, "Taken.").in_sequence(notify)
			move.do_get(bob, "##{cheese}")
			assert_equal(NOTHING, @db.get(bob).next)
			assert_equal(cheese, @db.get(bob).contents)
			assert_equal(exit, @db.get(cheese).next)
			
			# The wizard can reach about the place!
			# Put the cheese down again and pick-up from limbo
			record(exit) {|r| r[:next] = NOTHING }
			record(cheese) {|r| r.merge!({ :location => place, :next => NOTHING }) }
			record(bob) {|r| r.merge!({ :next => NOTHING, :contents => exit, :location => limbo }) }
			record(place) {|r| r.merge!({ :contents => cheese })}
			record(wizard) {|r| r[:next] = bob }
			Interface.expects(:do_notify).with(bob, "I don't see that here.").in_sequence(notify)
			move.do_get(bob, "cheese")
			Interface.expects(:do_notify).with(wizard, "I don't see that here.").in_sequence(notify)
			move.do_get(wizard, "cheese")
			Interface.expects(:do_notify).with(wizard, "Taken.").in_sequence(notify)
			move.do_get(wizard, "##{cheese}")
			assert_equal(cheese, @db.get(wizard).contents)
			assert_equal(wizard, @db.get(cheese).location)
		end
		
		def test_do_drop
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			place2 = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pod")
			cheese = @db.add_new_record
			cheese2 = @db.add_new_record
			ear = @db.add_new_record
			exit = @db.add_new_record
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM, :exits => NOTHING, :owner => anne }) }
			record(place2) {|r| r.merge!({:name => "place2", :description => "blue", :osucc => "ping", :contents => NOTHING, :flags => TYPE_ROOM, :exits => NOTHING, :owner => NOTHING }) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => cheese2, :exits => limbo }) }
			record(cheese2) {|r| r.merge!({ :name => "cheese2", :location => place, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => exit, :exits => limbo }) }
			record(ear) {|r| r.merge!({ :name => "ear", :location => place, :description => "pinkish", :flags => TYPE_THING, :owner => anne, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => ear ) }
			record(exit) {|r| r.merge!( :location => bob, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING ) }
			
			move = TinyMud::Move.new(@db)
			notify = sequence('notify')
		
			# Drop cheese whilst nowhere!
			record(bob) {|r| r[:location] = NOTHING }
			move.do_drop(bob, "cheese")
			assert_equal(cheese, @db.get(bob).contents)
			
			# Drop something you don't have (put bob back first)
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			Interface.expects(:do_notify).with(bob, "You don't have that!").in_sequence(notify)
			move.do_drop(bob, "ear")
			
			# Drop something you own but its location isn't on you (shouldn't occur)
			Interface.expects(:do_notify).with(bob, "You can't drop that.").in_sequence(notify)
			move.do_drop(bob, "cheese2")
			
			# Drop an exit in a room you don't own
			Interface.expects(:do_notify).with(bob, "You can't put an exit down here.").in_sequence(notify)
			move.do_drop(bob, "exit")
			
			# Drop an exit in a place you own
			record(place) {|r| r[:owner] = bob }
			Interface.expects(:do_notify).with(bob, "Exit dropped.").in_sequence(notify)
			move.do_drop(bob, "exit")
			assert_equal(exit, @db.get(place).exits)
			assert_equal(NOTHING, @db.get(exit).location)
			assert_equal(NOTHING, @db.get(cheese2).next)
			
			# Drop something you own onto a temple
			record(place) {|r| r[:flags] = r[:flags] | TEMPLE }
			Interface.expects(:do_notify).with(bob, "cheese is consumed in a burst of flame!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob sacrifices cheese.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(cheese2, @db.get(bob).contents)
			assert_equal(limbo, @db.get(cheese).location)

			# Drop again, don't own, but make the reward < 1
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :location => bob, :next => NOTHING, :owner => anne, :pennies => 0 )}
			Interface.expects(:do_notify).with(bob, "cheese is consumed in a burst of flame!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob sacrifices cheese.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have received 1 penny for your sacrifice.").in_sequence(notify)
			move.do_drop(bob, "cheese")

			# Drop again, don't own, have more than MAX_PENNIES
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :location => bob, :next => NOTHING, :owner => anne, :pennies => 10 )}
			record(bob) {|r| r.merge!( :pennies => MAX_PENNIES + 1 ) }
			Interface.expects(:do_notify).with(bob, "cheese is consumed in a burst of flame!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob sacrifices cheese.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have received 1 penny for your sacrifice.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			record(bob) {|r| r.merge!( :pennies => 5 ) }

			# Drop again, don't own, but make the reward > MAX_OBJECT_ENDOWMENT
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :location => bob, :next => NOTHING, :owner => anne, :pennies => MAX_OBJECT_ENDOWMENT + 1 )}
			Interface.expects(:do_notify).with(bob, "cheese is consumed in a burst of flame!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob sacrifices cheese.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have received #{MAX_OBJECT_ENDOWMENT} pennies for your sacrifice.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			
			# The same but you don't own it
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :location => bob, :next => NOTHING, :owner => anne, :pennies => 5 )}
			Interface.expects(:do_notify).with(bob, "cheese is consumed in a burst of flame!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob sacrifices cheese.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have received 5 pennies for your sacrifice.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(cheese2, @db.get(bob).contents)
			assert_equal(limbo, @db.get(cheese).location)
			
			# Drop a sticky thing (goes home)
			record(place) {|r| r[:flags] = TYPE_ROOM } # Undo temple
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :location => bob, :next => NOTHING, :owner => bob )}
			record(cheese) {|r| r[:flags] = r[:flags] | STICKY }
			Interface.expects(:do_notify).with(bob, "Dropped.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(cheese2, @db.get(bob).contents)
			assert_equal(limbo, @db.get(cheese).location)
			
			# Drop in a non sticky place that has a location!
			record(place) {|r| r[:location] = place2 }
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :flags => TYPE_THING, :location => bob, :next => NOTHING, :owner => bob )}
			Interface.expects(:do_notify).with(bob, "Dropped.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(place2, @db.get(cheese).location)
			
			# Drop in a sticky place that has a location (location ignored!
			record(place) {|r| r[:flags] = r[:flags] | STICKY }
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :flags => TYPE_THING, :location => bob, :next => NOTHING, :owner => bob )}
			Interface.expects(:do_notify).with(bob, "Dropped.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob dropped cheese.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(place, @db.get(cheese).location)
			assert_equal(cheese, @db.get(place).contents)
			
			# Finally thing drops as expected!
			record(place) {|r| r.merge!( { :flags => TYPE_ROOM, :location => NOTHING, :contents => bob } ) } # Undo above
			record(cheese2) {|r| r[:next] = cheese }
			record(cheese) {|r| r.merge!( :flags => TYPE_THING, :location => bob, :next => NOTHING, :owner => bob )}
			Interface.expects(:do_notify).with(bob, "Dropped.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob dropped cheese.").in_sequence(notify)
			move.do_drop(bob, "cheese")
			assert_equal(place, @db.get(cheese).location)
		end

		def set_up_objects(start_loc, bob, anne, jim, place)
			limbo = 0
			wizard = 1
			record(limbo) {|r| r[:contents] = wizard }
			record(wizard) {|r| r[:next] = NOTHING }
			# Note: ensure name is set - NULL ptr errors otherwise
			record(start_loc) {|r| r.merge!({:name => "somewhere", :contents => bob, :flags => TYPE_ROOM }) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => jim, :flags => TYPE_ROOM }) }
			record(bob) {|r| r.merge!({ :location => start_loc, :exits => limbo, :flags => TYPE_PLAYER, :next => anne }) } # Home is at limbo
			record(anne) {|r| r.merge!({ :location => start_loc, :flags => TYPE_PLAYER, :next => NOTHING }) }
			record(jim) {|r| r.merge!({ :location => place, :name => "slim jim", :description => "Tall", :exits => limbo, :flags => TYPE_PLAYER, :next => NOTHING }) }
		end
    end
end
