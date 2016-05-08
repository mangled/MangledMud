require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestRob < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = minimal()
      @notifier = mock()

      # Ensure we only kill or get pennies when we want to
      Game.stubs(:do_rand).returns(17)
    end

    def teardown
      @db.free()
    end

    def test_do_rob
      limbo = 0
      wizard = 1
      place = @db.add_new_record
      bob = Player.new(@db, @notifier).create_player("bob", "sprout")
      anne = Player.new(@db, @notifier).create_player("anne", "treacle")
      cheese = @db.add_new_record
      jam = @db.add_new_record
      exit = @db.add_new_record
      record(place) {|r| r.merge!({ :location => limbo, :name => "place", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
      record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
      record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
      record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
      record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => NOTHING  }) }
      record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }

      rob = MangledMud::Rob.new(@db, @notifier)
      notify = sequence('notify')

      # Player in nothing
      @notifier.expects(:do_notify).never.in_sequence(notify)
      record(bob) {|r| r[:location] = NOTHING }
      rob.do_rob(bob, "cheese")
      record(bob) {|r| r[:location] = place }

      # Rob a non-existant thing
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('rob-whom')).in_sequence(notify)
      rob.do_rob(bob, "earwig")

      # Rob someone not in the same location
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('rob-whom')).in_sequence(notify)
      assert_equal("Wizard", @db[wizard].name)
      rob.do_rob(bob, "Wizard")

      # Rob a non player item on me
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-only-rob-players')).in_sequence(notify)
      rob.do_rob(bob, "jam")

      # Rob a poor player
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('penniless', "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('tried-to-rob-you', "bob")).in_sequence(notify)
      rob.do_rob(bob, "anne")

      # Rob player
      record(anne) {|r| r[:pennies] = 1 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('stole-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('stole-from-you', "bob")).in_sequence(notify)
      rob.do_rob(bob, "anne")
      assert_equal(0, @db[anne].pennies)
      assert_equal(1, @db[bob].pennies)

      # Weird logic related to anti lock and keys, this will be tested elsewhere through a mock, so trigger it for now
      record(anne) {|r| r.merge!({ :pennies => 1, :key => bob, :flags => TYPE_PLAYER | ANTILOCK }) }
      @notifier.expects(:do_notify).with(bob, "Your conscience tells you not to.").in_sequence(notify)
      rob.do_rob(bob, "anne")

      # Rob self!
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('stole-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('stole-from-you', "bob")).in_sequence(notify)
      assert_equal(1, @db[bob].pennies)
      rob.do_rob(bob, "bob")
      assert_equal(1, @db[bob].pennies)

      # Rob a wizard!
      record(anne) {|r| r.merge!({ :pennies => 1, :flags => TYPE_PLAYER | WIZARD }) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('stole-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('stole-from-you', "bob")).in_sequence(notify)
      rob.do_rob(bob, "anne")

      # Wizards can use absolutes and reach anywhere!
      record(anne) {|r| r.merge!({ :pennies => 1, :key => NOTHING, :flags => TYPE_PLAYER }) }
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('stole-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('stole-from-you', "Wizard")).in_sequence(notify)
      rob.do_rob(wizard, "anne")

      record(anne) {|r| r.merge!({ :pennies => 1, :key => NOTHING, :flags => TYPE_PLAYER }) }
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('stole-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('stole-from-you', "Wizard")).in_sequence(notify)
      rob.do_rob(wizard, "##{anne}")

      # Key seems to impact a wizard too
      record(anne) {|r| r.merge!({ :pennies => 1, :key => bob, :flags => TYPE_PLAYER }) }
      @notifier.expects(:do_notify).with(wizard, "Your conscience tells you not to.").in_sequence(notify)
      rob.do_rob(wizard, "##{anne}")

      # Ambiguous
      another_anne = Player.new(@db, @notifier).create_player("annie", "treacle")
      record(anne) {|r| r.merge!( :next => wizard ) }
      record(wizard) {|r| r.merge!( :location => place, :next => another_anne ) }
      record(another_anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('who'))
      rob.do_rob(wizard, "an")
    end

    def test_do_kill
      limbo = 0
      wizard = 1
      place = @db.add_new_record
      cabin = @db.add_new_record
      bob = Player.new(@db, @notifier).create_player("bob", "sprout")
      anne = Player.new(@db, @notifier).create_player("anne", "treacle")
      sam = Player.new(@db, @notifier).create_player("sam", "sam")
      sue = Player.new(@db, @notifier).create_player("sue", "sam")
      jam = @db.add_new_record
      record(limbo) {|r| r.merge!({ :contents => wizard, :flags => TYPE_ROOM, :next => NOTHING }) }
      record(place) {|r| r.merge!({ :location => NOTHING, :name => "place", :contents => bob, :flags => TYPE_ROOM, :next => NOTHING }) }
      record(bob) {|r| r.merge!( :contents => NOTHING, :location => place, :next => anne ) }
      record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam, :exits => limbo ) }
      record(jam) {|r| r.merge!({ :name => "jam", :location => place, :flags => TYPE_THING, :owner => anne, :next => sue  }) }
      record(sue) {|r| r.merge!( :contents => NOTHING, :location => place, :next => NOTHING ) }
      record(cabin) {|r| r.merge!({ :location => NOTHING, :name => "cabin", :contents => sam, :flags => TYPE_ROOM, :next => NOTHING }) }
      record(sam) {|r| r.merge!( :contents => NOTHING, :location => cabin, :next => NOTHING, :exits => limbo ) }

      rob = MangledMud::Rob.new(@db, @notifier)
      notify = sequence('notify')

      # Player somewhere else
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('dont-see-player')).in_sequence(notify)
      rob.do_kill(bob, "Wizard", 1)

      # Made up player
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('dont-see-player')).in_sequence(notify)
      rob.do_kill(bob, "Wonka", 1)

      # Kill a thing!
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-only-kill-players')).in_sequence(notify)
      rob.do_kill(bob, "jam", 1)

      # Kill a wizard
      record(anne) {|r| r.merge!({ :flags => TYPE_PLAYER | WIZARD }) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('sorry-wizard-immortal')).in_sequence(notify)
      rob.do_kill(bob, "anne", 1)

      # Kill but poor!
      record(anne) {|r| r.merge!({ :flags => TYPE_PLAYER }) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('too-poor')).in_sequence(notify)
      rob.do_kill(bob, "anne", 1)

      # Kill but rich, setting cost to greater than KILL_BASE_COST to ensure success (uses random in code)
      record(bob) {|r| r.merge!({ :pennies => KILL_BASE_COST + 1000 }) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('killed', "You", "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('killed-you', "bob")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, "Your insurance policy pays 50 pennies.").in_sequence(notify)
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('player-left', "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(sue, Phrasebook.lookup('player-left', "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('player-arrived', "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, "Limbo").in_sequence(notify) # her exit = home
      @notifier.expects(:do_notify).with(anne, @db[limbo].description).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, "anne " + @db[limbo].osucc).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('contents')).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, "Wizard").in_sequence(notify)
      # This is random and may or may not trigger, need to resolve as tests become unreliable
      # Comment out this line and remove +1 below if this test "randomly" fails!
      # @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('found-a-penny')).in_sequence(notify)
      @notifier.expects(:do_notify).with(sue, Phrasebook.lookup('killed', "bob", "anne")).in_sequence(notify)
      rob.do_kill(bob, "anne", KILL_BASE_COST)
      assert_equal(KILL_BONUS + 0, @db[anne].pennies) # The +1 is a result of the random, see comment above
      assert_equal(limbo, @db[anne].location)
      assert_equal(jam, @db[bob].next)
      assert_equal(1000, @db[bob].pennies)

      # Kill but almost poor, being a wizard so I don't need to move stuff about, also tests wizard powers
      record(bob) {|r| r.merge!({ :flags => TYPE_PLAYER | WIZARD, :pennies => KILL_MIN_COST }) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('murder-failed')).in_sequence(notify)
      @notifier.expects(:do_notify).with(sam, Phrasebook.lookup('tried-to-kill-you', "bob")).in_sequence(notify)
      rob.do_kill(bob, "##{sam}", 1)
      assert_equal(place, @db[sue].location)
      assert_equal(sue, @db[jam].next)
      assert_equal(KILL_MIN_COST, @db[bob].pennies)

      # Ambiguous
      another_sue = Player.new(@db, @notifier).create_player("susan", "treacle")
      record(sue) {|r| r.merge!( :next => another_sue ) }
      record(another_sue) {|r| r.merge!( :contents => NOTHING, :location => place, :next => NOTHING ) }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('who'))
      rob.do_kill(bob, "su", 1)
    end

    def test_do_give
      limbo = 0
      wizard = 1
      place = @db.add_new_record
      bob = Player.new(@db, @notifier).create_player("bob", "sprout")
      anne = Player.new(@db, @notifier).create_player("anne", "treacle")
      cheese = @db.add_new_record
      jam = @db.add_new_record
      exit = @db.add_new_record
      record(place) {|r| r.merge!({ :location => limbo, :name => "place", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
      record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
      record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
      record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
      record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => NOTHING  }) }
      record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }

      rob = MangledMud::Rob.new(@db, @notifier)
      notify = sequence('notify')

      # Wizards can "rob" this way, but bob isn't!
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('try-rob-command')).in_sequence(notify)
      rob.do_give(bob, "anne", -1)

      # Zero give
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('specify-positive-pennies')).in_sequence(notify)
      rob.do_give(bob, "anne", 0)

      # Person not real
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('give-to-whom')).in_sequence(notify)
      rob.do_give(bob, "tulip", 1)

      # Person not here
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('give-to-whom')).in_sequence(notify)
      rob.do_give(bob, "wizard", 1)

      # Again, not sure how to generate ambiguous test!!!

      # Not a person (and in location) - silent!!!
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('can-only-give-to-others')).in_sequence(notify)
      rob.do_give(bob, "jam", 1)

      # Amount trips max
      record(anne) {|r| r[:pennies] = MAX_PENNIES - 1 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('player-too-rich')).in_sequence(notify)
      rob.do_give(bob, "anne", 2)

      # Ok, but poor
      record(anne) {|r| r[:pennies] = 0 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('not-rich-enough')).in_sequence(notify)
      rob.do_give(bob, "anne", 1)

      # Ok
      record(bob) {|r| r[:pennies] = 4 }
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('you-give-a-penny', "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('gives-you-a-penny', "bob")).in_sequence(notify)
      rob.do_give(bob, "anne", 1)
      assert_equal(3, @db[bob].pennies)
      assert_equal(1, @db[anne].pennies)

      # Ok, but plural
      @notifier.expects(:do_notify).with(bob, Phrasebook.lookup('you-give-pennies', "2", "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('gives-you-pennies', "bob", "2")).in_sequence(notify)
      rob.do_give(bob, "anne", 2)
      assert_equal(1, @db[bob].pennies)
      assert_equal(3, @db[anne].pennies)

      # Wizard can use absolute and rob!
      @notifier.expects(:do_notify).with(wizard, "You give -1 pennies to anne.").in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, "Wizard gives you -1 pennies.").in_sequence(notify)
      rob.do_give(wizard, "##{anne}", -1)
      assert_equal(2, @db[anne].pennies)

      # Wizard can use name (not in room)
      @notifier.expects(:do_notify).with(wizard, "You give -1 pennies to anne.").in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, "Wizard gives you -1 pennies.").in_sequence(notify)
      rob.do_give(wizard, "anne", -1)
      assert_equal(1, @db[anne].pennies)

      # Wizard can give to non player objects!!!!
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('you-give-a-penny', "jam")).in_sequence(notify)
      rob.do_give(wizard, "jam", 1)
      assert_equal(1, @db[jam].pennies)

      # Need to be in a location?
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('give-to-whom')).in_sequence(notify)
      rob.do_give(wizard, "cheese", 1)

      # Wizard can give more than max
      record(anne) {|r| r[:pennies] = MAX_PENNIES - 1 }
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('you-give-pennies', "2", "anne")).in_sequence(notify)
      @notifier.expects(:do_notify).with(anne, Phrasebook.lookup('gives-you-pennies', "Wizard", "2")).in_sequence(notify)
      rob.do_give(wizard, "anne", 2)
      assert_equal(MAX_PENNIES + 1, @db[anne].pennies)

      # Ambiguous
      another_anne = Player.new(@db, @notifier).create_player("annie", "treacle")
      record(anne) {|r| r.merge!( :next => wizard ) }
      record(wizard) {|r| r.merge!( :location => place, :next => another_anne ) }
      record(another_anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
      @notifier.expects(:do_notify).with(wizard, Phrasebook.lookup('who'))
      rob.do_give(wizard, "an", 2)
    end
  end
end
