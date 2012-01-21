require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require_relative 'helpers'
require 'pp'

module TinyMud
    class TestRob < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_do_rob
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new.create_player("bob", "sprout")
			anne = Player.new.create_player("anne", "treacle")
			cheese = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(place) {|r| r.merge!({ :location => limbo, :name => "place", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => NOTHING  }) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			
			rob = TinyMud::Rob.new
			notify = sequence('notify')
			
			# Player in nothing
			Interface.expects(:do_notify).never.in_sequence(notify)
			record(bob) {|r| r[:location] = NOTHING }
			rob.do_rob(bob, "cheese")
			record(bob) {|r| r[:location] = place }
			
			# Rob a non-existant thing
			Interface.expects(:do_notify).with(bob, "Rob whom?").in_sequence(notify)
			rob.do_rob(bob, "earwig")
			
			# Rob someone not in the same location
			Interface.expects(:do_notify).with(bob, "Rob whom?").in_sequence(notify)
			assert_equal("Wizard", @db.get(wizard).name)
			rob.do_rob(bob, "Wizard")
			
			# Rob a non player item on me
			Interface.expects(:do_notify).with(bob, "Sorry, you can only rob other players.").in_sequence(notify)
			rob.do_rob(bob, "jam")
			
			# Rob a poor player
			Interface.expects(:do_notify).with(bob, "anne is penniless.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob tried to rob you, but you have no pennies to take.").in_sequence(notify)
			rob.do_rob(bob, "anne")
			
			# Rob player
			record(anne) {|r| r[:pennies] = 1 }
			Interface.expects(:do_notify).with(bob, "You stole a penny.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob stole one of your pennies!").in_sequence(notify)
			rob.do_rob(bob, "anne")
			assert_equal(0, @db.get(anne).pennies)
			assert_equal(1, @db.get(bob).pennies)
			
			# Weird logic related to anti lock and keys, this will be tested elsewhere through a mock, so trigger it for now
			record(anne) {|r| r.merge!({ :pennies => 1, :key => bob, :flags => TYPE_PLAYER | ANTILOCK }) }
			Interface.expects(:do_notify).with(bob, "Your conscience tells you not to.").in_sequence(notify)
			rob.do_rob(bob, "anne")

			# Rob self!
			Interface.expects(:do_notify).with(bob, "You stole a penny.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "bob stole one of your pennies!").in_sequence(notify)
			assert_equal(1, @db.get(bob).pennies)
			rob.do_rob(bob, "bob")
			assert_equal(1, @db.get(bob).pennies)

			# Rob a wizard!
			record(anne) {|r| r.merge!({ :pennies => 1, :flags => TYPE_PLAYER | WIZARD }) }
			Interface.expects(:do_notify).with(bob, "You stole a penny.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob stole one of your pennies!").in_sequence(notify)
			rob.do_rob(bob, "anne")

			# Wizards can use absolutes and reach anywhere!
			record(anne) {|r| r.merge!({ :pennies => 1, :key => NOTHING, :flags => TYPE_PLAYER }) }
			Interface.expects(:do_notify).with(wizard, "You stole a penny.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard stole one of your pennies!").in_sequence(notify)
			rob.do_rob(wizard, "anne")
			
			record(anne) {|r| r.merge!({ :pennies => 1, :key => NOTHING, :flags => TYPE_PLAYER }) }
			Interface.expects(:do_notify).with(wizard, "You stole a penny.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard stole one of your pennies!").in_sequence(notify)
			rob.do_rob(wizard, "##{anne}")
			
			# Key seems to impact a wizard too
			record(anne) {|r| r.merge!({ :pennies => 1, :key => bob, :flags => TYPE_PLAYER }) }
			Interface.expects(:do_notify).with(wizard, "Your conscience tells you not to.").in_sequence(notify)
			rob.do_rob(wizard, "##{anne}")

			# Ambiguous
			another_anne = Player.new.create_player("annie", "treacle")
			record(anne) {|r| r.merge!( :next => wizard ) }
			record(wizard) {|r| r.merge!( :location => place, :next => another_anne ) }
			record(another_anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			Interface.expects(:do_notify).with(wizard, "I don't know who you mean!")
			rob.do_rob(wizard, "an")
		end

		def test_do_kill
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			cabin = @db.add_new_record
			bob = Player.new.create_player("bob", "sprout")
			anne = Player.new.create_player("anne", "treacle")
			sam = Player.new.create_player("sam", "sam")
			sue = Player.new.create_player("sue", "sam")
			jam = @db.add_new_record
			record(limbo) {|r| r.merge!({ :contents => wizard, :flags => TYPE_ROOM, :next => NOTHING }) }
			record(place) {|r| r.merge!({ :location => NOTHING, :name => "place", :contents => bob, :flags => TYPE_ROOM, :next => NOTHING }) }
			record(bob) {|r| r.merge!( :contents => NOTHING, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam, :exits => limbo ) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :flags => TYPE_THING, :owner => anne, :next => sue  }) }
			record(sue) {|r| r.merge!( :contents => NOTHING, :location => place, :next => NOTHING ) }
			record(cabin) {|r| r.merge!({ :location => NOTHING, :name => "cabin", :contents => sam, :flags => TYPE_ROOM, :next => NOTHING }) }
			record(sam) {|r| r.merge!( :contents => NOTHING, :location => cabin, :next => NOTHING, :exits => limbo ) }
			
			rob = TinyMud::Rob.new
			notify = sequence('notify')
			
			# Player somewhere else
			Interface.expects(:do_notify).with(bob, "I don't see that player here.").in_sequence(notify)
			rob.do_kill(bob, "Wizard", 1)
			
			# Made up player
			Interface.expects(:do_notify).with(bob, "I don't see that player here.").in_sequence(notify)
			rob.do_kill(bob, "Wonka", 1)
			
			# Kill a thing!
			Interface.expects(:do_notify).with(bob, "Sorry, you can only kill other players.").in_sequence(notify)
			rob.do_kill(bob, "jam", 1)
			
			# Kill a wizard
			record(anne) {|r| r.merge!({ :flags => TYPE_PLAYER | WIZARD }) }
			Interface.expects(:do_notify).with(bob, "Sorry, Wizards are immortal.").in_sequence(notify)
			rob.do_kill(bob, "anne", 1)
			
			# Kill but poor!
			record(anne) {|r| r.merge!({ :flags => TYPE_PLAYER }) }
			Interface.expects(:do_notify).with(bob, "You don't have enough pennies.").in_sequence(notify)
			rob.do_kill(bob, "anne", 1)
			
			# Kill but rich, setting cost to greater than KILL_BASE_COST to ensure success (uses random in code)
			record(bob) {|r| r.merge!({ :pennies => KILL_BASE_COST + 1 }) } # 1 < KILL_MIN_COST gets rounded to it
			Interface.expects(:do_notify).with(bob, "You killed anne!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob killed you!").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Your insurance policy pays 50 pennies.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne has left.").in_sequence(notify)
			Interface.expects(:do_notify).with(sue, "anne has left.").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "anne has arrived.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Limbo").in_sequence(notify) # her exit = home
			Interface.expects(:do_notify).with(anne, @db.get(limbo).description).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "anne " + @db.get(limbo).osucc).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard").in_sequence(notify)
			# This is random and may or may not trigger, need to resolve as tests become unreliable
			# Comment out this line and remove +1 below if this test "randomly" fails!
			#Interface.expects(:do_notify).with(anne, "You found a penny!").in_sequence(notify)
			Interface.expects(:do_notify).with(sue, "bob killed anne!").in_sequence(notify)
			rob.do_kill(bob, "anne", KILL_BASE_COST)
			assert_equal(KILL_BONUS + 0, @db.get(anne).pennies) # The +1 is a result of the random, see comment above
			assert_equal(limbo, @db.get(anne).location)
			assert_equal(jam, @db.get(bob).next)
			assert_equal(1, @db.get(bob).pennies)

			# Kill but almost poor - NOTE this relies on the random number generator!!! It may fail
			# once in a while!!! Being a wizard so I don't need to move stuff about, also tests wizard
			# powers
			record(bob) {|r| r.merge!({ :flags => TYPE_PLAYER | WIZARD, :pennies => KILL_MIN_COST }) }
			Interface.expects(:do_notify).with(bob, "Your murder attempt failed.").in_sequence(notify)
			Interface.expects(:do_notify).with(sam, "bob tried to kill you!").in_sequence(notify)
			rob.do_kill(bob, "##{sam}", 1)
			assert_equal(place, @db.get(sue).location)
			assert_equal(sue, @db.get(jam).next)
			assert_equal(KILL_MIN_COST, @db.get(bob).pennies)

			# Ambiguous
			another_sue = Player.new.create_player("susan", "treacle")
			record(sue) {|r| r.merge!( :next => another_sue ) }
			record(another_sue) {|r| r.merge!( :contents => NOTHING, :location => place, :next => NOTHING ) }
			Interface.expects(:do_notify).with(bob, "I don't know who you mean!")
			rob.do_kill(bob, "su", 1)
		end
		
		def test_do_give
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new.create_player("bob", "sprout")
			anne = Player.new.create_player("anne", "treacle")
			cheese = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(place) {|r| r.merge!({ :location => limbo, :name => "place", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => NOTHING  }) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			
			rob = TinyMud::Rob.new
			notify = sequence('notify')
			
			# Wizards can "rob" this way, but bob isn't!
			Interface.expects(:do_notify).with(bob, "Try using the \"rob\" command.").in_sequence(notify)
			rob.do_give(bob, "anne", -1)
			
			# Zero give
			Interface.expects(:do_notify).with(bob, "You must specify a positive number of pennies.").in_sequence(notify)
			rob.do_give(bob, "anne", 0)
			
			# Person not real
			Interface.expects(:do_notify).with(bob, "Give to whom?").in_sequence(notify)
			rob.do_give(bob, "tulip", 1)

			# Person not here
			Interface.expects(:do_notify).with(bob, "Give to whom?").in_sequence(notify)
			rob.do_give(bob, "wizard", 1)
			
			# Again, not sure how to generate ambiguous test!!!
			
			# Not a person (and in location) - silent!!!
			Interface.expects(:do_notify).with(bob, "You can only give to other players.").in_sequence(notify)
			rob.do_give(bob, "jam", 1)
			
			# Amount trips max
			record(anne) {|r| r[:pennies] = MAX_PENNIES - 1 }
			Interface.expects(:do_notify).with(bob, "That player doesn't need that many pennies!").in_sequence(notify)
			rob.do_give(bob, "anne", 2)
			
			# Ok, but poor
			record(anne) {|r| r[:pennies] = 0 }
			Interface.expects(:do_notify).with(bob, "You don't have that many pennies to give!").in_sequence(notify)
			rob.do_give(bob, "anne", 1)
			
			# Ok
			record(bob) {|r| r[:pennies] = 4 }
			Interface.expects(:do_notify).with(bob, "You give 1 penny to anne.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob gives you 1 penny.").in_sequence(notify)
			rob.do_give(bob, "anne", 1)
			assert_equal(3, @db.get(bob).pennies)
			assert_equal(1, @db.get(anne).pennies)
			
			# Ok, but plural
			Interface.expects(:do_notify).with(bob, "You give 2 pennies to anne.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob gives you 2 pennies.").in_sequence(notify)
			rob.do_give(bob, "anne", 2)
			assert_equal(1, @db.get(bob).pennies)
			assert_equal(3, @db.get(anne).pennies)
			
			# Wizard can use absolute and rob!
			Interface.expects(:do_notify).with(wizard, "You give -1 pennies to anne.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard gives you -1 pennies.").in_sequence(notify)
			rob.do_give(wizard, "##{anne}", -1)
			assert_equal(2, @db.get(anne).pennies)
			
			# Wizard can use name (not in room)
			Interface.expects(:do_notify).with(wizard, "You give -1 pennies to anne.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard gives you -1 pennies.").in_sequence(notify)
			rob.do_give(wizard, "anne", -1)
			assert_equal(1, @db.get(anne).pennies)
			
			# Wizard can give to non player objects!!!!
			Interface.expects(:do_notify).with(wizard, "You give 1 penny to jam.").in_sequence(notify)
			rob.do_give(wizard, "jam", 1)
			assert_equal(1, @db.get(jam).pennies)

			# Need to be in a location?
			Interface.expects(:do_notify).with(wizard, "Give to whom?").in_sequence(notify)
			rob.do_give(wizard, "cheese", 1)
			
			# Wizard can give more than max
			record(anne) {|r| r[:pennies] = MAX_PENNIES - 1 }
			Interface.expects(:do_notify).with(wizard, "You give 2 pennies to anne.").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard gives you 2 pennies.").in_sequence(notify)
			rob.do_give(wizard, "anne", 2)
			assert_equal(MAX_PENNIES + 1, @db.get(anne).pennies)

			# Ambiguous
			another_anne = Player.new.create_player("annie", "treacle")
			record(anne) {|r| r.merge!( :next => wizard ) }
			record(wizard) {|r| r.merge!( :location => place, :next => another_anne ) }
			record(another_anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			Interface.expects(:do_notify).with(wizard, "I don't know who you mean!")
			rob.do_give(wizard, "an", 2)
		end
    end
end
