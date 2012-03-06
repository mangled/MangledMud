require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'

module TinyMud
    class TestGame < Test::Unit::TestCase
		def setup
			@db = Db.Minimal()
			@notifier = mock()
			@notify = sequence('notify')
		end

		def test_process_command
			limbo = 0
			wizard = 1
			# We need some players - Creation elsewhere (@notifier.c - tested elsewhere)
			bob = Player.new(@db, @notifier).create_player("bob", "sprout")
			sam = Player.new(@db, @notifier).create_player("sam", "sprout")

			game = TinyMud::Game.new(@db, "dumpfile", @notifier)
			@notifier.expects(:do_emergency_shutdown).never
			
			# Bad player ref goes to stderr!
			game.process_command(-1, "foo")
			
			# Simple (one character) commands
			#
			# Say
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('you-say', "treacle")).in_sequence(@notify)
			@notifier.expects(:do_notify).with(sam, Phrasebook.lookup('someone-says', "bob", "treacle")).in_sequence(@notify)
			@notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('someone-says', "bob", "treacle")).in_sequence(@notify)
			game.process_command(bob, '"treacle')
			
			# Pose
			@notifier.expects(:do_notify).with(sam, 'bob treacle').in_sequence(@notify)
			@notifier.expects(:do_notify).with(bob, 'bob treacle').in_sequence(@notify)
			@notifier.expects(:do_notify).with(wizard, 'bob treacle').in_sequence(@notify)
			game.process_command(bob, ":treacle")

			# news and @toad must match completely
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
			game.process_command(bob, "new")
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
			game.process_command(bob, "@toa")

			# Others don't e.g. drop
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('dont-have-it')).in_sequence(@notify)
			game.process_command(bob, "dr")

			# !! Command is an exact match for an exit - Check later - We don't have an exit!!!
			
			# Bad command (doesn't start with @)
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
			game.process_command(bob, "!treacle")

			# Do a shutdown as a non-wizard
			@notifier.expects(:do_notify).with(bob, Phrasebook.lookup('delusional'))
			game.do_shutdown(bob)

			# Shutdown as a wizard
			game.do_shutdown(wizard)

			# This kills further processing
			assert_raise RuntimeError do
				game.process_command(wizard, "!treacle")
			end

			# The rest of the testing of "game" is handled through regression.rb
		end

		def teardown
			@db.free()
		end
    end
end
