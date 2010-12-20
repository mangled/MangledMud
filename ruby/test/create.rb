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
		
		def test_do_link
			# TODO!
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
