require 'rubygems'
require 'mocha'
require 'test/unit'
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
			puts @db.get(0).contents
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
