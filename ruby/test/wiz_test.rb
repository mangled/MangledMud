require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'

module TinyMud
    class TestWiz < Test::Unit::TestCase
        
        include TestHelpers
        
		def setup
			@db = Db.Minimal()

			# Ensure we never give pennies
			Game.stubs(:do_rand).returns(1)
		end

		def teardown
			@db.free()
		end
		
		def test_do_teleport
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "sprout")
			anne = Player.new(@db).create_player("anne", "treacle")
			cheese = @db.add_new_record
			jam = @db.add_new_record
			another_jam = @db.add_new_record
			exit = @db.add_new_record
			another_place = @db.add_new_record
			record(limbo) {|r| r.merge!({ :contents => wizard }) }
			record(place) {|r| r.merge!({ :location => limbo, :name => "place", :contents => bob, :flags => TYPE_ROOM, :exits => NOTHING }) }
			record(another_place) {|r| r.merge!({ :location => limbo, :name => "placeplace", :contents => NOTHING, :flags => TYPE_ROOM, :exits => NOTHING }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => another_jam  }) }
			record(another_jam) {|r| r.merge!({ :name => "jamm", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => exit  }) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }

			wiz = TinyMud::Wiz.new(@db)
			notify = sequence('notify')
			
			# Only a wizard can do this
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('bad-teleport')).in_sequence(notify)
			wiz.do_teleport(bob, nil, nil)
			
			# Wizard can teleport self - first to non-existant location
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('send-where')).in_sequence(notify)
			wiz.do_teleport(wizard, "outer space", nil)
			
			# A location not "here"
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('send-where')).in_sequence(notify)
			wiz.do_teleport(wizard, "place", nil)
			
			# Use absolute
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('feel-weird')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('player-arrived', "Wizard")).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, Phrasebook.lookup('player-arrived', "Wizard")).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "place (#2)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob(#3)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "anne(#4)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "jam(#6)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "jamm(#7)").in_sequence(notify)
			wiz.do_teleport(wizard, "##{place}", nil)
			assert_equal(place, @db[wizard].location)
			assert_equal(wizard, @db[place].contents)
			
			# Can't see rooms by name?
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('dont-see-that')).in_sequence(notify)
			wiz.do_teleport(wizard, "place", "##{limbo}")

			# Can't send "to" exit or things
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('bad-destination')).in_sequence(notify)
			wiz.do_teleport(wizard, "anne", "jam")
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('bad-destination')).in_sequence(notify)
			wiz.do_teleport(wizard, "anne", "exit")
			
			# Can't send exit or room
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('bad-destination')).in_sequence(notify)
			wiz.do_teleport(wizard, "exit", "##{limbo}")
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('bad-destination')).in_sequence(notify)
			wiz.do_teleport(wizard, "##{place}", "##{limbo}")
			
			# Can send things
			assert_equal(place, @db[jam].location)
			wiz.do_teleport(wizard, "jam", "##{limbo}")
			assert_equal(limbo, @db[jam].location)
			assert_equal(jam, @db[limbo].contents)
			
			# Can send here
			wiz.do_teleport(wizard, "##{jam}", "here")
			assert_equal(place, @db[jam].location)
			
			# Ambiguous
			wiz.do_teleport(wizard, "##{another_jam}", "here")
			assert_equal(place, @db[another_jam].location)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('which-one'))
			wiz.do_teleport(wizard, "ja", "##{limbo}")

			another_bob = Player.new(@db).create_player("bobby", "sprout")
			record(another_bob) {|r| r.merge!( :contents => NOTHING, :location => limbo, :next => NOTHING ) }
			record(limbo) {|r| r.merge!({ :contents => another_bob }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('feel-weird')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('player-left', "bob")).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, Phrasebook.lookup('player-left', "bob")).in_sequence(notify)
			Interface.expects(:do_notify).with(another_bob, Phrasebook.lookup('player-arrived', "bob")).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Limbo").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db[limbo].description}").in_sequence(notify)
			Interface.expects(:do_notify).with(another_bob, "bob is briefly visible through the mist.").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, 'bobby').in_sequence(notify)
			wiz.do_teleport(wizard, "##{bob}", "##{limbo}")
			assert_equal(limbo, @db[bob].location)
			assert_equal(limbo, @db[another_bob].location)
			assert_equal(place, @db[wizard].location)

			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('feel-weird')).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, Phrasebook.lookup('player-left', "Wizard")).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('player-arrived', "Wizard")).in_sequence(notify)
			Interface.expects(:do_notify).with(another_bob, Phrasebook.lookup('player-arrived', "Wizard")).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "Limbo (#0)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "#{@db[limbo].description}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard is briefly visible through the mist.").in_sequence(notify)
			Interface.expects(:do_notify).with(another_bob, "Wizard is briefly visible through the mist.").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, 'bob(#3)').in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, 'bobby(#10)').in_sequence(notify)
			wiz.do_teleport(wizard, "##{limbo}", nil)
			
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('which-dest'))
			wiz.do_teleport(wizard, "##{jam}", "bo")
		end

		def test_do_force
			limbo = 0
			wizard = 1
			bob = Player.new(@db).create_player("bob", "sprout")

			wiz = TinyMud::Wiz.new(@db)
			notify = sequence('notify')
			
			# Only a wizard can use this
			Interface.expects(:do_process_command).never.in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('only-wizard')).in_sequence(notify)
			wiz.do_force(nil, bob, nil, nil)
			
			# Victim must exist
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('player-does-not-exist')).in_sequence(notify)
			wiz.do_force(nil, wizard, "spider", nil)
			
			# Pass the call on to process_command
			Interface.expects(:do_process_command).with(bob, "twig").returns(0).in_sequence(notify)
			wiz.do_force(nil, wizard, "bob", "twig")
		end

		def test_do_stats
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "sprout")
			anne = Player.new(@db).create_player("anne", "treacle")
			cheese = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			unknown = @db.add_new_record
			record(limbo) {|r| r.merge!({ :contents => wizard }) }
			record(place) {|r| r.merge!({ :location => limbo, :name => "place", :owner => bob, :contents => bob, :flags => TYPE_ROOM, :exits => NOTHING }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => NOTHING  }) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			record(unknown) {|r| r.merge!( :flags => 0xFF ) }
			
			wiz = TinyMud::Wiz.new(@db)
			notify = sequence('notify')
			
			# Non wizards get minimal stats (the second arg is ignored)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('universe-contains', @db.length)).in_sequence(notify)
			wiz.do_stats(bob, nil)
			
			# Wizard can get stats on any player, will count all non-owned items and (if "player" matches their matches), no player match...
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('universe-details', 9, 2, 1, 2, 3, 1)).in_sequence(notify)
			wiz.do_stats(wizard, "wig")
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('universe-details', 3, 1, 0, 1, 1, 0)).in_sequence(notify)
			wiz.do_stats(wizard, "bob")
		end
		
		def test_do_toad
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "sprout")
			anne = Player.new(@db).create_player("anne", "treacle")
			cheese = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(limbo) {|r| r.merge!({ :contents => wizard }) }
			record(place) {|r| r.merge!({ :location => limbo, :name => "place", :owner => bob, :contents => bob, :flags => TYPE_ROOM, :exits => NOTHING }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => NOTHING, :location => place, :next => jam ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING  }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => place, :description => "red", :flags => TYPE_THING, :owner => NOTHING, :next => exit  }) }
			record(exit) {|r| r.merge!( :location => limbo, :name => "exit", :description => "long", :flags => TYPE_EXIT, :next => NOTHING ) }
			
			wiz = TinyMud::Wiz.new(@db)
			notify = sequence('notify')
			
			# Only wizards can do this
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('bad-toad')).in_sequence(notify)
			wiz.do_toad(bob, "anne")
			
			# Must exist
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('dont-see-that')).in_sequence(notify)
			wiz.do_toad(wizard, "twig")
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('dont-see-that')).in_sequence(notify)
			wiz.do_toad(wizard, "##{@db.length}")
			
			# Must be a player
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('can-only-toad-players')).in_sequence(notify)
			wiz.do_toad(wizard, "##{jam}")
			
			# Can't be another wizard
			record(bob) {|r| r[:flags] = r[:flags] | WIZARD }
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('cant-toad-wizard')).in_sequence(notify)
			wiz.do_toad(wizard, "##{bob}")
			
			# They can't be carrying anything
			record(bob) {|r| r[:flags] = r[:flags] = TYPE_PLAYER }
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('what-about-them')).in_sequence(notify)
			wiz.do_toad(wizard, "##{bob}")
			
			# Do-it :-)
			record(anne) {|r| r[:flags] = r[:flags] | DARK } # To check flags reset
			record(anne) {|r| r[:pennies] = 100 }
			record(anne) {|r| r[:owner] = NOTHING }
			Interface.expects(:do_notify).with(anne, Phrasebook.lookup('you-become-a-toad')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('you-toaded', "anne")).in_sequence(notify)
			wiz.do_toad(wizard, "##{anne}")
			assert_equal(wizard, @db[anne].owner)
			assert_equal(1, @db[anne].pennies)
			assert_equal(nil, @db[anne].password)
			assert_equal(TYPE_THING, @db[anne].flags)
			assert_equal("a slimy toad named anne", @db[anne].name)
		end
    end
end
