require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestMatch < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = minimal()
      @notifier = mock()
    end

    def teardown
      @db.free()
    end

    def test_match_player
      player_ref = Player.new(@db, @notifier).create_player("bob", "pwd")
      assert_equal(2, player_ref)
      wizard = 1

      match = Match.new(@db, @notifier)
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
      assert_equal(10 - LOOKUP_COST, @db[player_ref].pennies)
      # Garbage player name!
      match.init_match(player_ref, "*anne", -1)
      match.match_player
      assert_equal(10 - (2 * LOOKUP_COST), @db[player_ref].pennies)
      check_match_states(match, NOTHING, player_ref)
    end

    def test_match_absolute
      wizard = 1 # Any player will do
      match = Match.new(@db, @notifier)

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
      wizard = 1 # Any player will do
      match = Match.new(@db, @notifier)
      match.init_match(wizard, "wizard", -1) # Type doesn't matter for this
      match.match_me
      check_match_states(match, NOTHING, wizard)
      match.init_match(wizard, "me", -1)
      match.match_me
      check_match_states(match, wizard)
    end

    def test_match_here
      wizard = 1 # Any player will do

      match = Match.new(@db, @notifier)
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
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      f = lambda {|match| match.match_possession }
      check_match_list(bob, bob, f)
    end

    # Similar comments to the above!
    def test_match_neighbor
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      record(bob) {|r| r[:location] = 0}
      f = lambda {|match| match.match_neighbor }
      check_match_list(bob, 0, f)
    end

    def test_match_exit
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")
      wizard = 1
      match = Match.new(@db, @notifier)

      # Person can't be at NOTHING
      record(bob) {|r| r[:location] = NOTHING }
      match.init_match(bob, "fig", -1)
      match.match_exit()
      check_match_states(match, NOTHING, bob)
      record(bob) {|r| r[:location] = 0 }
      # Set-up
      exitn = @db.add_new_record
      exitw = @db.add_new_record
      exits = @db.add_new_record
      exite = @db.add_new_record
      record(exitn) {|r| r.merge!({ :flags => TYPE_EXIT, :name => "n;north", :owner => bob, :next => exitw }) }
      record(exitw) {|r| r.merge!({ :flags => TYPE_EXIT, :name => "w;west", :owner => bob, :next => exits }) }
      record(exits) {|r| r.merge!({ :flags => TYPE_EXIT, :name => "s ;south", :owner => bob }) }
      record(exite) {|r| r.merge!({ :flags => TYPE_EXIT, :name => "e;east", :owner => wizard }) }
      record(0) {|r| r[:exits] = exitn }

      # If we specify an absolute name we should find it (if we own it), first a garbage reference
      match.init_match(bob, "#32", -1)
      match.match_exit()
      check_match_states(match, NOTHING, bob)
      match.init_match(bob, "##{exite}", -1)
      match.match_exit()
      check_match_states(match, NOTHING, bob)
      match.init_match(bob, "##{exits}", -1)
      match.match_exit()
      check_match_states(match, exits)
      match.init_match(wizard, "##{exits}", -1) # wizard can see all
      match.match_exit()
      check_match_states(match, exits)

      # Now see if we can find exits by name
      match.init_match(bob, "south", -1)
      match.match_exit()
      check_match_states(match, exits)
      match.init_match(wizard, "south", -1)
      match.match_exit()
      check_match_states(match, exits)
      match.init_match(bob, "e", -1)
      match.match_exit()
      check_match_states(match, NOTHING, bob)

      # Note: The code does call check_keys, but the result doesn't go anywhere (exit_status)
      # so there isn't any point in testing "init_match_check_keys"!!! Dead code! Still, lets
      # prod it anyway...
      record(exits) {|r| r.merge!({ :key => NOTHING }) }
      match.init_match_check_keys(bob, "south", -1)
      match.match_exit()
      check_match_states(match, exits)
    end

    def test_match_everything
      # This calls all the match methods - I don't have the energy or desire to test this!
      # It has a switch on the wizard. Once I have a ruby version it will be easy to mock
      # to verify - I have tests for the underlying methods.
      # Check calling it works though!
      wizard = 1
      match = Match.new(@db, @notifier)
      match.init_match(wizard, "foo", -1)
      match.match_everything
      check_match_states(match, NOTHING, wizard)
    end

    # Specific test that invokes a random decision for choosing a match - match possesion
    # isn't the only possible function which will invoke this, but we just want to hit
    # the random call, so it will do (for coverage)
    puts "Fyi - If you get changes in the regression output then try disabling this!!!"
    def test_match_list_for_random_decision
      wizard = 1
      match = Match.new(@db, @notifier)
      # Some fake things for the owner
      thing1 = @db.add_new_record
      thing2 = @db.add_new_record
      thing3 = @db.add_new_record
      # Join them up
      record(thing1) {|r| r.merge!({ :flags => TYPE_THING, :name => "glove", :owner => wizard, :next => thing2 }) }
      record(thing2) {|r| r.merge!({ :flags => TYPE_THING, :name => "spoon", :owner => wizard, :next => thing3 }) }
      record(thing3) {|r| r.merge!({ :flags => TYPE_THING, :name => "glove", :owner => wizard }) }
      record(wizard) {|r| r.merge!({ :contents => thing1 })}
      # Get the wizard to match possesion
      match.init_match(wizard, "glove", -1)
      match.match_possession
      random = match.last_match_result()
      assert(random == thing1 || random == thing3, "expected a choice between #{thing1} and #{thing3}")
    end

    # Helpers
    #########

    def check_match_list(person, owner, f)
      # Some fake things for the owner
      thing1 = @db.add_new_record
      thing2 = @db.add_new_record
      thing3 = @db.add_new_record
      # Join them up
      record(thing1) {|r| r.merge!({ :flags => TYPE_THING, :name => "glove", :owner => owner, :next => thing2 }) }
      record(thing2) {|r| r.merge!({ :flags => TYPE_THING, :name => "socks", :owner => owner, :next => thing3 }) }
      record(thing3) {|r| r.merge!({ :flags => TYPE_THING, :name => "pants", :owner => owner }) }

      match = Match.new(@db, @notifier)
      # owner has nothing
      match.init_match(person, "fig", -1)
      f.call(match)
      check_match_states(match, NOTHING, person)
      # Give owner some things
      record(owner) {|r| r[:contents] = thing1 }
      match.init_match(person, "glove", -1)
      f.call(match)
      check_match_states(match, thing1)
      match.init_match(person, "pants", -1)
      f.call(match)
      check_match_states(match, thing3)
      # Try absolute name for thing - person must own for this (for neighbour check i.e. in room and owner! This is a bug?)
      record(thing3) {|r| r[:owner] = person }
      match.init_match(person, "#5", -1)
      f.call(match)
      check_match_states(match, thing3)
      # Try sub string match
      match.init_match(person, "pa", -1)
      f.call(match)
      check_match_states(match, thing3, person)
      # Now add another similarly named thing - We should get an AMBIGUOUS match
      thing4 = @db.add_new_record
      record(thing3) {|r| r[:next] = thing4 }
      record(thing4) {|r| r.merge!({ :flags => TYPE_THING, :name => "pan", :owner => owner }) }
      match.init_match(person, "pa", -1)
      f.call(match)
      @notifier.expects(:do_notify).never
      assert_equal(AMBIGUOUS, match.match_result())
      assert_equal(thing4, match.last_match_result())
      @notifier.expects(:do_notify).with(person, Phrasebook.lookup('which-one'))
      assert_equal(NOTHING, match.noisy_match_result())
      # If he had multiple items of the same name then a random ref would be returned
      # This isn't a perfect test but will do for now - Really need to mock inner methods
      record(thing4) {|r| r.merge!({ :name => "pants", :flags => TYPE_EXIT}) }
      match.init_match(person, "pants", TYPE_THING)
      f.call(match)
      assert_equal(thing3, match.match_result())
      match.init_match(person, "pants", TYPE_EXIT)
      f.call(match)
      assert_equal(thing4, match.match_result())
      # Now match with keys - This occurs when we have ambiguity - multiple matches
      # as above, but each item is checked to see if the person can perform actions
      # on the things.
      location = @db.add_new_record
      record(thing3) {|r| r.merge!({ :location => location, :key => NOTHING, :flags =>  TYPE_THING }) } # printf, no idea whats going on!
      record(thing4) {|r| r.merge!({ :location => NOTHING, :key => NOTHING, :flags =>  TYPE_THING }) }
      match.init_match_check_keys(person, "pants", NOTYPE)
      f.call(match)
      assert_equal(thing3, match.match_result())
      record(thing3) {|r| r.merge!({ :location => NOTHING, :key => NOTHING, :flags =>  TYPE_THING }) } # printf, no idea whats going on!
      record(thing4) {|r| r.merge!({ :location => location, :key => NOTHING, :flags =>  TYPE_THING }) }
      match.init_match_check_keys(person, "pants", NOTYPE)
      f.call(match)
      assert_equal(thing4, match.match_result())
    end

    def check_match_states(match, match_who = NOTHING, notify_who = NOTHING)
      @notifier.expects(:do_notify).never
      assert_equal(match_who, match.match_result())
      assert_equal(match_who, match.last_match_result())
      if (match_who == NOTHING)
        @notifier.expects(:do_notify).with(notify_who, Phrasebook.lookup('dont-see-that'))
        assert_equal(match_who, match.noisy_match_result())
      else
        @notifier.expects(:do_notify).never
        assert_equal(match_who, match.noisy_match_result())
      end
    end
  end
end
