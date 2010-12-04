require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestMatch < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_match_player
			Db.Minimal()
			player_ref = Player.new.create_player("bob", "pwd")
			assert_equal(2, player_ref)
			wizard = 1

			match = Match.new
			match.init_match(player_ref, "bob", -1) # Type doesn't matter for this
			check_match_states(match, NOTHING, player_ref)
			# Must have a * and the player must have at least LOOKUP_COST pennies
			match.init_match(player_ref, "*bob", -1) # Type doesn't matter for this
			match.match_player
			check_match_states(match, NOTHING, player_ref)
			record(player_ref) {|r| r[:pennies] = 10 }
			match.init_match(player_ref, "*  bob", -1) # Type doesn't matter for this
			match.match_player
			check_match_states(match, player_ref)
			assert_equal(10 - LOOKUP_COST, @db.get(player_ref).pennies)
			# Garbage player name!
			match.init_match(player_ref, "*anne", -1)
			match.match_player
			assert_equal(10 - (2 * LOOKUP_COST), @db.get(player_ref).pennies)
			check_match_states(match, NOTHING, player_ref)
		end
		
		def test_match_absolute
			Db.Minimal()
			wizard = 1 # Any player will do
			match = Match.new

			# No token => No match
			match.init_match(wizard, "wizard", -1) # Type doesn't matter for this
			match.match_absolute
			check_match_states(match, NOTHING, wizard)
			# With token below valid range
			match.init_match(wizard, "#-1", -1)
			match.match_absolute
			check_match_states(match, NOTHING, wizard)
			# With token above valid range
			match.init_match(wizard, "#100", -1)
			match.match_absolute
			check_match_states(match, NOTHING, wizard)
			# Valid
			match.init_match(wizard, "#1", -1)
			match.match_absolute
			check_match_states(match, wizard)
		end
		
		def test_match_me
			Db.Minimal()
			wizard = 1 # Any player will do
			match = Match.new
			match.init_match(wizard, "wizard", -1) # Type doesn't matter for this
			match.match_me
			check_match_states(match, NOTHING, wizard)
			match.init_match(wizard, "me", -1)
			match.match_me
			check_match_states(match, wizard)
		end
		
		def test_match_here
			Db.Minimal()
			wizard = 1 # Any player will do

			match = Match.new
			# match name must be here and who mustn't be nowhere
			match.init_match(wizard, "wizard", -1) # Type doesn't matter for this
			record(wizard) {|r| r[:location] = NOTHING }
			match.match_here
			check_match_states(match, NOTHING, wizard)
			match.init_match(wizard, "here", -1)
			match.match_here
			check_match_states(match, NOTHING, wizard)
			record(wizard) {|r| r[:location] = 0 }
			match.match_here
			check_match_states(match, 0, wizard)
		end
		
		# match something player is carrying
		# This requires mocking to completely test (it has random behaviour)
		# This is mostly covered, it's quite complicated and has a number of
		# branch points.
		def test_match_possession
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			# Some fake things for the player
			thing1 = @db.add_new_record
			thing2 = @db.add_new_record
			thing3 = @db.add_new_record
			# Join them up
			record(thing1) {|r| r.merge!({ :flags => TYPE_THING, :name => "glove", :owner => bob, :next => thing2 }) }
			record(thing2) {|r| r.merge!({ :flags => TYPE_THING, :name => "socks", :owner => bob, :next => thing3 }) }
			record(thing3) {|r| r.merge!({ :flags => TYPE_THING, :name => "pants", :owner => bob }) }
			
			match = Match.new
			# Bob has nothing
			match.init_match(bob, "fig", -1)
			match.match_possession
			check_match_states(match, NOTHING, bob)
			# Give bob some things
			record(bob) {|r| r[:contents] = thing1 }
			match.init_match(bob, "glove", -1)
			match.match_possession
			check_match_states(match, thing1)
			match.init_match(bob, "pants", -1)
			match.match_possession
			check_match_states(match, thing3)
			# Try absolute name for thing
			match.init_match(bob, "#5", -1)
			match.match_possession
			check_match_states(match, thing3)
			# Try sub string match
			match.init_match(bob, "pa", -1)
			match.match_possession
			check_match_states(match, thing3, bob)
			# Now add another similarly names thing - We should get an AMBIGUOUS match
			thing4 = @db.add_new_record
			record(thing3) {|r| r[:next] = thing4 }
			record(thing4) {|r| r.merge!({ :flags => TYPE_THING, :name => "pan", :owner => bob }) }
			match.init_match(bob, "pa", -1)
			match.match_possession
			Interface.expects(:do_notify).never
			assert_equal(AMBIGUOUS, match.match_result())
			assert_equal(thing4, match.last_match_result())
			Interface.expects(:do_notify).with(bob, AMBIGUOUS_MESSAGE)
			assert_equal(NOTHING, match.noisy_match_result())
			# If he had multiple items of the same name then a random ref would be returned
			# This isn't a perfect test but will do for now - Really need to mock inner methods
			record(thing4) {|r| r.merge!({ :name => "pants", :flags => TYPE_EXIT}) }
			match.init_match(bob, "pants", TYPE_THING) # Type does effect
			match.match_possession
			assert_equal(thing3, match.match_result())
			match.init_match(bob, "pants", TYPE_EXIT) # Type does effect
			match.match_possession
			assert_equal(thing4, match.match_result())
		end
		
		def test_match_neighbor
			Db.Minimal()
			match = Match.new
			match.init_match(0, "", NOTYPE)
			match.match_neighbor
			# TODO - This is basically the same as the above! Except it looks
			# in the persons location's contents - Could I weld the tests
			# together?
		end
		
		def check_match_states(match, match_who = NOTHING, notify_who = NOTHING)
			Interface.expects(:do_notify).never
			assert_equal(match_who, match.match_result())
			assert_equal(match_who, match.last_match_result())
			if (match_who == NOTHING)
				Interface.expects(:do_notify).with(notify_who, NOMATCH_MESSAGE)
				assert_equal(match_who, match.noisy_match_result())
			else
				Interface.expects(:do_notify).never
				assert_equal(match_who, match.noisy_match_result())
			end
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
