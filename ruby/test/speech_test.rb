require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require_relative 'helpers'
require 'pp'

module TinyMud
    class TestSpeech < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = TinyMud::Db.new()
		end

		def teardown
			@db.free()
		end
		
		def test_reconstruct_message
			speech = Speech.new(@db)
			assert_equal("hello", speech.reconstruct_message("hello", nil))
			assert_equal("hello = world", speech.reconstruct_message("hello", "world"))
		end
		
		def test_do_say
			Db.Minimal()
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			joe = Player.new(@db).create_player("joe", "pod")
			speech = Speech.new(@db)
			
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
			bob = Player.new(@db).create_player("bob", "pwd")
			joe = Player.new(@db).create_player("joe", "pod")
			speech = Speech.new(@db)

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
			bob = Player.new(@db).create_player("bob", "pwd")
			joe = Player.new(@db).create_player("joe", "pod")
			speech = Speech.new(@db)
			
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
			bob = Player.new(@db).create_player("bob", "pwd")
			record(bob) {|r| r[:location] = 0 }
			Interface.expects(:do_notify).with(bob, 'Your complaint has been duly noted.')
			Speech.new(@db).do_gripe(bob, "darn trolls", "eat cheese")
			# Fixme: write stderr to somewhere else
		end

		def test_do_page
			Db.Minimal()
			wizard = 1
			bob = Player.new(@db).create_player("bob", "pwd")
			joe = Player.new(@db).create_player("joe", "pod")

			speech = Speech.new(@db)
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
			bob = Player.new(@db).create_player("bob", "pwd")
			joe = Player.new(@db).create_player("joe", "pod")
			
			# Not sure if you chain people like this but its only testing the "next" chain on an object
			record(wizard) {|r| r[:next] = bob }
			record(bob) {|r| r[:next] = joe }
			record(joe) {|r| r[:next] = NOTHING }
			
			speech = Speech.new(@db)
			Interface.expects(:do_notify).with(wizard, "foo")
			Interface.expects(:do_notify).with(bob, "foo")
			speech.notify_except(wizard, joe, "foo")
			
			Interface.expects(:do_notify).never
			Interface.expects(:do_notify).with(joe, "foo")
			Interface.expects(:do_notify).with(bob, "foo")
			speech.notify_except(wizard, wizard, "foo")
		end
    end
end
