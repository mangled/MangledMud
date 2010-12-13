require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestMove < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_moveto
			Db.Minimal()
			wizard = 1
			somewhere = @db.add_new_record
			record(somewhere) {|r| r[:contents] = NOTHING }
			bob = Player.new.create_player("bob", "pwd")

			move = TinyMud::Move.new
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
			bob = Player.new.create_player("bob", "pwd")
			anne = Player.new.create_player("anne", "pod")
			jim = Player.new.create_player("jim", "pds")
			start_loc = @db.add_new_record
			place = @db.add_new_record

			move = TinyMud::Move.new

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
			
			###############################################
			# !!! Work out how to test finding a penny !!!!
			###############################################
			# Doesn't show up because the random number generator is reset each time
		end
		
		def test_send_home
			Db.Minimal()
			limbo = 0
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			anne = Player.new.create_player("anne", "pod")
			cheese = @db.add_new_record
			place = @db.add_new_record

			move = TinyMud::Move.new

			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM, :next => NOTHING }) }
			record(anne) {|r| r.merge!({ :location => limbo, :exits => NOTHING, :flags => TYPE_PLAYER, :next => NOTHING, :contents => NOTHING }) }
			record(bob) {|r| r.merge!({ :location => place, :exits => limbo, :flags => TYPE_PLAYER, :next => NOTHING, :contents => cheese }) } # Home is at limbo
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :location => place, :owner => bob, :next => NOTHING, :exits => limbo }) }

			# Send bob home (note it hangs!!! if only the wizard is in limbo - possibly limbo can't be home)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(anne, 'bob has arrived.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(limbo).description).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, 'bob is briefly visible through the mist.').in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese(#4)").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			move.send_home(bob)
			assert_equal(limbo, @db.get(cheese).location)
			assert_equal(bob, @db.get(cheese).owner)
			assert_equal(NOTHING, @db.get(bob).contents)

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
			move = TinyMud::Move.new
			assert_equal(1, move.can_move(0, "home"))
			
			# Check players directions
			bob = Player.new.create_player("bob", "pwd")
			anne = Player.new.create_player("anne", "pod")
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
			bob = Player.new.create_player("bob", "pwd")
			anne = Player.new.create_player("anne", "pod")
			jim = Player.new.create_player("jim", "pds")
			start_loc = @db.add_new_record
			place = @db.add_new_record
			cheese = @db.add_new_record

			move = TinyMud::Move.new

			# Move to same location
			set_up_objects(start_loc, bob, anne, jim, place)
			record(cheese) {|r| r.merge!({ :name => "cheese", :description => "wiffy", :flags => TYPE_THING, :location => start_loc, :owner => bob, :next => NOTHING, :exits => place }) }
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
			
			# Ambiguous exit - ***THIS LOOKS BROKEN*** re. getting an ambiguous match - Need to look closer!
			exits = @db.add_new_record
			exitw = @db.add_new_record
			#record(exits) {|r| r.merge!( :location => place, :name => "spooky", :description => "long", :flags => TYPE_EXIT, :next => exitw ) }
			#record(exitw) {|r| r.merge!( :location => limbo, :name => "spooky", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			#record(start_loc) {|r| r[:exits] = exits }
			#move.do_move(bob, "spooky")

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
