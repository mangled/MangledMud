require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestSpeech < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_reconstruct_message
			speech = Speech.new
			assert_equal("hello", speech.reconstruct_message("hello", nil))
			assert_equal("hello = world", speech.reconstruct_message("hello", "world"))
		end
		
		def test_do_say
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			joe = Player.new.create_player("joe", "pod")
			speech = Speech.new
			
			# If the player is nowhere then nothing is heard
			Interface.expects(:do_notify).never
			record(bob) {|r| r[:location] = NOTHING }
			speech.do_say(bob, "hello", "world")
			
			# If the player is somewhere
			notify = sequence('notify')
			Interface.expects(:do_notify).with(bob, "You say \"hello = world\"").in_sequence(notify)
			Interface.expects(:do_notify).with(joe, "bob says \"hello = world\"").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob says \"hello = world\"").in_sequence(notify)
			record(bob) {|r| r[:location] = 0 }
			speech.do_say(bob, "hello", "world")
		end
		
		def test_do_pose
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			joe = Player.new.create_player("joe", "pod")
			speech = Speech.new

			# If the player is nowhere then nothing is heard
			Interface.expects(:do_notify).never
			record(bob) {|r| r[:location] = NOTHING }
			speech.do_pose(bob, "hello", "world")
			
			# If the player is somewhere
			notify = sequence('notify')
			Interface.expects(:do_notify).with(joe, "bob hello = world").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "bob hello = world").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob hello = world").in_sequence(notify)
			record(bob) {|r| r[:location] = 0 }
			speech.do_pose(bob, "hello", "world")
		end
		
		def test_do_wall
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			joe = Player.new.create_player("joe", "pod")
			speech = Speech.new
			
			# Normal player
			Interface.expects(:do_notify).with(joe, 'But what do you want to do with the wall?')
			speech.do_wall(joe, "hello", "world")
			
			# Wizard
			notify = sequence('notify')
			Interface.expects(:do_notify).with(wizard, "Wizard shouts \"hello = world\"").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard shouts \"hello = world\"").in_sequence(notify)
			Interface.expects(:do_notify).with(joe, "Wizard shouts \"hello = world\"").in_sequence(notify)
			speech.do_wall(wizard, "hello", "world")
			# Fixme: write stderr to somewhere else
		end

		def test_do_gripe
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			record(bob) {|r| r[:location] = 0 }
			Interface.expects(:do_notify).with(bob, 'Your complaint has been duly noted.')
			Speech.new.do_gripe(bob, "darn trolls", "eat cheese")
			# Fixme: write stderr to somewhere else
		end

		def test_do_page
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			joe = Player.new.create_player("joe", "pod")

			speech = Speech.new
			record(bob) {|r| r[:pennies] = 0 }
			Interface.expects(:do_notify).with(bob, "You don't have enough pennies.")
			speech.do_page(bob, "joe")
			
			record(bob) {|r| r[:pennies] = LOOKUP_COST }
			Interface.expects(:do_notify).with(bob, "I don't recognize that name.")
			speech.do_page(bob, "jed")
			
			record(bob) {|r| r[:pennies] = LOOKUP_COST }
			Interface.expects(:do_notify).with(joe, "You sense that bob is looking for you in Limbo.")
			Interface.expects(:do_notify).with(bob, "Your message has been sent.")
			speech.do_page(bob, "joe")
		end

		def test_notify_except
			Db.Minimal()
			wizard = 1
			bob = Player.new.create_player("bob", "pwd")
			joe = Player.new.create_player("joe", "pod")
			
			# Not sure if you chain people like this but its only testing the "next" chain on an object
			record(wizard) {|r| r[:next] = bob }
			record(bob) {|r| r[:next] = joe }
			record(joe) {|r| r[:next] = NOTHING }
			
			speech = Speech.new
			Interface.expects(:do_notify).with(wizard, "foo")
			Interface.expects(:do_notify).with(bob, "foo")
			speech.notify_except(wizard, joe, "foo")
			
			Interface.expects(:do_notify).never
			Interface.expects(:do_notify).with(joe, "foo")
			Interface.expects(:do_notify).with(bob, "foo")
			speech.notify_except(wizard, wizard, "foo")
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
