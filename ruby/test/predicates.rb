require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestPlayer < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end

		def test_can_link_to
			# where must be valid, the where must be a room, who must either control (own) where or where is LINK_OK
			Db.Minimal()

			# Make a minimal new player - This should be a helper at some point?
			player_ref = Player.new.create_player("bob", "pwd")
			assert_equal(2, player_ref)

			pred = Predicates.new
			assert_equal(0, pred.can_link_to(0, -1)) # Where < 0
			assert_equal(0, pred.can_link_to(0, @db.length)) # where > db_top
			assert_equal(0, pred.can_link_to(0, 1)) # where points to non-room (wizard)

			assert_equal(1, pred.can_link_to(1, 0)) # who = Wizard = 1 = controls all
			
			assert_equal(0, pred.can_link_to(player_ref, 0)) # who = "bob" = 2 = controls nothing, limbo no LINK_OK
			record(0) {|r| r[:flags] = TYPE_ROOM | LINK_OK }
			assert_equal(1, pred.can_link_to(player_ref, 0)) # who = "bob" = 2 = controls nothing, limbo LINK_OK

			# Create an object "bob" owns
			obj_ref = @db.add_new_record
			record(obj_ref) {|r| r.merge!({:flags => TYPE_ROOM, :owner => player_ref}) }
			assert_equal(1, pred.can_link_to(player_ref, obj_ref)) # who = "bob" = 2 = controls object

			# Bob doesn't own, but linking is allowed
			record(obj_ref) {|r| r.merge!({:flags => TYPE_ROOM | LINK_OK, :owner => 1}) }
			assert_equal(1, pred.can_link_to(player_ref, obj_ref)) # who = "bob" = 2 = doesn't control object but it allows links
		end
		
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
					record.name = value if value
				when :description
					record.description = value if value
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
					record.fail = value if value
				when :succ
					record.succ = value if value
				when :ofail
					record.ofail = value if value
				when :osucc
					record.osucc = value if value
				when :owner
					record.owner = value
				when :pennies
					record.pennies = value
				when :flags
					record.flags = value
				when :password
					record.password = value if value
				else
					raise("Record - unknown key #{key} with #{value}")
				end
			end

			@db.put(i, record)
		end
    end
end
