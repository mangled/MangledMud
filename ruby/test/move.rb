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
