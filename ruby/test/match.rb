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
