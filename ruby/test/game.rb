require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'tinymud'
require 'pp'

module TinyMud
    class TestGame < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
			@notify = sequence('notify')
		end

		def test_process_command
			Db.Minimal()
			limbo = 0
			wizard = 1
			# We need some players - Creation elsewhere (interface.c - tested elsewhere)
			bob = Player.new.create_player("bob", "sprout")
			sam = Player.new.create_player("sam", "sprout")

			game = TinyMud::Game.new
			Interface.expects(:do_emergency_shutdown).never
			
			# Bad player ref goes to stderr!
			game.process_command(-1, "foo")
			
			# Simple (one character) commands
			#
			# Say
			Interface.expects(:do_notify).with(bob, 'You say "treacle"').in_sequence(@notify)
			Interface.expects(:do_notify).with(sam, 'bob says "treacle"').in_sequence(@notify)
			Interface.expects(:do_notify).with(wizard, 'bob says "treacle"').in_sequence(@notify)
			game.process_command(bob, '"treacle')
			
			# Pose
			Interface.expects(:do_notify).with(sam, 'bob treacle').in_sequence(@notify)
			Interface.expects(:do_notify).with(bob, 'bob treacle').in_sequence(@notify)
			Interface.expects(:do_notify).with(wizard, 'bob treacle').in_sequence(@notify)
			game.process_command(bob, ":treacle")
			
			# !! Command is an exact match for an exit - Check later - We don't have an exit!!!
			
			# Bad command (doesn't start with @)
			Interface.expects(:do_notify).with(bob, 'Huh?  (Type "help" for help.)').in_sequence(@notify)
			game.process_command(bob, "!treacle")
			
			# The rest of the testing of "game" is handled through regression.rb
		end

		def teardown
			@db.free()
		end
    end
end
