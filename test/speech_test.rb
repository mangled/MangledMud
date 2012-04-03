require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestSpeech < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = minimal()
      @notifier = mock()
    end

    def teardown
      @db.free()
    end

    def test_do_say
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      joe = Player.new(@db, @notifier).create_player("joe", "pod")
      speech = Speech.new(@db, @notifier)

      # If the player is nowhere then nothing is heard
      @notifier.expects(:do_notify).never
      record(bob) {|r| r[:location] = NOTHING }
      speech.do_say(bob, "hello", "world")

      # If the player is somewhere
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('you-say', "hello = world")).in_sequence(notify)
      @notifier.expects(:do_notify).with(joe, Phrasebook.lookup('someone-says', "bob", "hello = world")).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('someone-says', "bob", "hello = world")).in_sequence(notify)
      record(bob) {|r| r[:location] = 0 }
      speech.do_say(bob, "hello", "world")
    end

    def test_do_pose
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      joe = Player.new(@db, @notifier).create_player("joe", "pod")
      speech = Speech.new(@db, @notifier)

      # If the player is nowhere then nothing is heard
      @notifier.expects(:do_notify).never
      record(bob) {|r| r[:location] = NOTHING }
      speech.do_pose(bob, "hello", "world")

      # If the player is somewhere
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(joe, "bob hello = world").in_sequence(notify)
      @notifier.expects(:do_notify).with(bob, "bob hello = world").in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, "bob hello = world").in_sequence(notify)
      record(bob) {|r| r[:location] = 0 }
      speech.do_pose(bob, "hello", "world")
    end

    def test_do_wall
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      joe = Player.new(@db, @notifier).create_player("joe", "pod")
      speech = Speech.new(@db, @notifier)

      # Normal player
      @notifier.expects(:do_notify).with(joe, Phrasebook.lookup('what-wall'))
      speech.do_wall(joe, "hello", "world")

      # Wizard
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('someone-shouts', "Wizard", "hello = world")).in_sequence(notify)
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('someone-shouts', "Wizard", "hello = world")).in_sequence(notify)
      @notifier.expects(:do_notify).with(joe, Phrasebook.lookup('someone-shouts', "Wizard", "hello = world")).in_sequence(notify)
      speech.do_wall(wizard, "hello", "world")
      # Fixme: write stderr to somewhere else
    end

    def test_do_gripe
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      record(bob) {|r| r[:location] = 0 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('complaint-noted'))
      Speech.new(@db, @notifier).do_gripe(bob, "darn trolls", "eat cheese")
      # Fixme: write stderr to somewhere else
    end

    def test_do_page
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      joe = Player.new(@db, @notifier).create_player("joe", "pod")

      speech = Speech.new(@db, @notifier)
      record(bob) {|r| r[:pennies] = 0 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('too-poor'))
      speech.do_page(bob, "joe")

      record(bob) {|r| r[:pennies] = LOOKUP_COST }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('unknown-name'))
      speech.do_page(bob, "jed")

      record(bob) {|r| r[:pennies] = LOOKUP_COST }
      @notifier.expects(:do_notify).with(joe, Phrasebook.lookup('someone-looking-for-you', "bob", "Limbo"))
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('message-sent'))
      speech.do_page(bob, "joe")
    end

    def test_notify_except
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      joe = Player.new(@db, @notifier).create_player("joe", "pod")

      # Not sure if you chain people like this but its only testing the "next" chain on an object
      record(wizard) {|r| r[:next] = bob }
      record(bob) {|r| r[:next] = joe }
      record(joe) {|r| r[:next] = NOTHING }

      speech = Speech.new(@db, @notifier)
      @notifier.expects(:do_notify).with(wizard, "foo")
      @notifier.expects(:do_notify).with(bob, "foo")
      speech.notify_except(wizard, joe, "foo")

      @notifier.expects(:do_notify).never
      @notifier.expects(:do_notify).with(joe, "foo")
      @notifier.expects(:do_notify).with(bob, "foo")
      speech.notify_except(wizard, wizard, "foo")
    end
  end
end
