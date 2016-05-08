require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'helpers'

module MangledMud

  class TestGame < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = minimal()
      @notifier = mock()
      @notify = sequence('notify')
    end

    def test_process_command
      limbo = 0
      wizard = 1
      # We need some players - Creation elsewhere (@notifier.c - tested elsewhere)
      bob = Player.new(@db, @notifier).create_player("bob", "sprout")
      sam = Player.new(@db, @notifier).create_player("sam", "sprout")

      game = MangledMud::Game.new(@db, "dumpfile", nil, nil) # help and news file's not checked = nil
      @notifier.expects(:update).never
      game.add_observer(@notifier)

      # Bad player ref goes to stderr!
      game.process_command(-1, "foo")

      # Simple (one character) commands
      #
      # Say
      @notifier.expects(:update).with(bob, Phrasebook.lookup('you-say', "treacle")).in_sequence(@notify)
      @notifier.expects(:update).with(sam, Phrasebook.lookup('someone-says', "bob", "treacle")).in_sequence(@notify)
      @notifier.expects(:update).with(wizard, Phrasebook.lookup('someone-says', "bob", "treacle")).in_sequence(@notify)
      game.process_command(bob, '"treacle')

      # Pose
      @notifier.expects(:update).with(sam, 'bob treacle').in_sequence(@notify)
      @notifier.expects(:update).with(bob, 'bob treacle').in_sequence(@notify)
      @notifier.expects(:update).with(wizard, 'bob treacle').in_sequence(@notify)
      game.process_command(bob, ":treacle")

      # news and @toad must match completely
      @notifier.expects(:update).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
      game.process_command(bob, "new")
      @notifier.expects(:update).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
      game.process_command(bob, "@toa")

      # Others don't e.g. drop
      @notifier.expects(:update).with(bob, Phrasebook.lookup('dont-have-it')).in_sequence(@notify)
      game.process_command(bob, "dr")

      # !! Command is an exact match for an exit - Check later - We don't have an exit!!!

      # Bad command (doesn't start with @)
      @notifier.expects(:update).with(bob, Phrasebook.lookup('huh')).in_sequence(@notify)
      game.process_command(bob, "!treacle")

      # Do a shutdown as a non-wizard
      @notifier.expects(:update).with(bob, Phrasebook.lookup('delusional'))
      game.process_command(bob, "@shutdown")

      # Shutdown as a wizard
      game.process_command(wizard, "@shutdown")

      # Game should be signalled as shutdown and should raise an error if process command is called.
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
