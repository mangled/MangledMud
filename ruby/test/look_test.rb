require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'


module TinyMud
    class TestLook < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = TinyMud::Db.new()
		end

		def teardown
			@db.free()
		end
		
		def test_look_room
			@db = Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			cheese = @db.add_new_record
			record(limbo) {|r| r.merge!( :contents => wizard ) }
			record(wizard) {|r| r.merge!( :next => bob ) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => NOTHING, :flags => TYPE_ROOM | LINK_OK, :exits => NOTHING }) }
			record(place) {|r| r.merge!({:fail => "fail", :succ => "success", :ofail => "ofail", :osucc => "osuccess" }) }
			record(bob) {|r| r.merge!( :contents => NOTHING, :location => limbo, :next => NOTHING ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			# look when can link to (owns or link ok set) - first link set (see above room flags)
			# Note: player doesn't need to be in the room!
			Interface.expects(:do_notify).with(bob, "#{@db[place].name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			look.look_room(bob, place)
			# Now player controls
			record(place) {|r| r.merge!({ :owner => bob, :flags => TYPE_ROOM }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			look.look_room(bob, place)
			# Now player doesn't control and no link_ok
			record(place) {|r| r.merge!({ :owner => NOTHING }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			look.look_room(bob, place)
			# Now create a "key", if the player doesn't have the key we fail
			record(place) {|r| r.merge!({ :key => cheese }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db[place].fail}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].ofail}").in_sequence(notify)
			look.look_room(bob, place)
			# Now bob is the key
			record(place) {|r| r.merge!({ :key => bob }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db[place].succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			look.look_room(bob, place)
			# Now bob holds the key
			record(place) {|r| r.merge!({ :key => cheese }) }
			record(bob) {|r| r.merge!({ :contents => cheese }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db[place].succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			look.look_room(bob, place)
			# Now put bob in the room - Should see the contents!
			record(limbo) {|r| r.merge!( :contents => NOTHING ) }
			record(wizard) {|r| r.merge!( :next => bob ) }
			record(place) {|r| r.merge!({ :contents => wizard }) }
			record(bob) {|r| r.merge!({ :next => cheese }) }
			record(cheese) {|r| r.merge!({ :location => place }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db[place].succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese(##{cheese})").in_sequence(notify)
			look.look_room(bob, place)
		end

		def test_do_look_around
			# This basically has one check then calls Look.look_room!!!
			# Not going to repeat all the look tests (above) again here.
			# Will check the guard though - Player @ nothing
			bob = Player.new(@db).create_player("bob", "pwd")
			place = @db.add_new_record
			record(bob) {|r| r.merge!( :contents => NOTHING, :location => NOTHING, :next => NOTHING ) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM | LINK_OK, :exits => NOTHING }) }
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			look.do_look_around(bob) # Should be a no-op

			# But I will sanity check the logic with one call - the look location
			# is extracted from the players current location, so
			record(bob) {|r| r.merge!({ :location => place }) }
			Interface.expects(:do_notify).with(bob, "#{@db[place].name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			look.do_look_around(bob)
		end

		def test_do_look_at
			@db = Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pwd")
			cheese = @db.add_new_record
			fish = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(limbo) {|r| r.merge!({:contents => NOTHING }) }
			record(wizard) {|r| r.merge!({:location => place, :next => NOTHING, :description => "A wizard!" }) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(fish) {|r| r.merge!({ :name => "fish", :location => place, :description => "slimy", :flags => TYPE_THING, :owner => anne, :next => wizard, :exits => limbo }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => anne, :description => "red", :flags => TYPE_THING, :owner => anne, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => jam, :location => place, :next => fish ) }
			record(exit) {|r| r.merge!( :location => place, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING ) }
			
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			# Look at nothing
			Interface.expects(:do_notify).with(bob, @db[place].name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "fish").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			look.do_look_at(bob, nil)
			# Look at something he doesn't own
			Interface.expects(:do_notify).with(bob, "slimy").in_sequence(notify)
			look.do_look_at(bob, "fish")
			# Look at something's he owns
			Interface.expects(:do_notify).with(bob, "wiffy").in_sequence(notify)
			look.do_look_at(bob, "cheese")
			Interface.expects(:do_notify).with(bob, "long").in_sequence(notify)
			look.do_look_at(bob, "exit")
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('see-nothing')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('carrying-list')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "jam").in_sequence(notify)
			look.do_look_at(bob, "anne")
			Interface.expects(:do_notify).with(bob, "A wizard!").in_sequence(notify)
			look.do_look_at(bob, "wizard")
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('dont-see-that')).in_sequence(notify)
			look.do_look_at(bob, "tree")
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('see-nothing')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('carrying-list')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese(#5)").in_sequence(notify)
			look.do_look_at(bob, "me")
			Interface.expects(:do_notify).with(bob, @db[place].name).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "bob #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "fish").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			look.do_look_at(bob, "here")
			# The wizard sees things with more precision!
			Interface.expects(:do_notify).with(wizard, "#{@db[place].name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(anne, "Wizard #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob(##{bob})").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "anne(##{anne})").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "fish(##{fish})").in_sequence(notify)
			look.do_look_at(wizard, "here")
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('see-nothing')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('carrying-list')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "cheese(#5)").in_sequence(notify)
			look.do_look_at(wizard, "bob")
		end

		def test_do_examine
			@db = Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pwd")
			cheese = @db.add_new_record
			fish = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(limbo) {|r| r.merge!({:contents => NOTHING }) }
			record(wizard) {|r| r.merge!({:location => place, :next => NOTHING, :description => "A wizard!" }) }
			record(place) {|r| r.merge!({:location => limbo, :name => "place", :description => "yellow", :succ=>"yippee", :fail => "shucks", :osucc => "ping", :ofail => "darn", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(fish) {|r| r.merge!({ :name => "fish", :location => place, :description => "slimy", :flags => TYPE_THING, :owner => anne, :next => wizard, :exits => limbo }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => anne, :description => "red", :flags => TYPE_THING, :owner => anne, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => jam, :location => place, :next => fish ) }
			record(exit) {|r| r.merge!( :location => place, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING ) }
			
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			# Look at place (non-owned)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('can-only-examine-owned')).in_sequence(notify)
			look.do_examine(bob, nil)
			# Now own
			record(place) {|r| r.merge!({ :owner => bob }) }
			Interface.expects(:do_notify).with(bob, "place(#2) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Room").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Fail: #{@db[place].fail}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Success: #{@db[place].succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Ofail: #{@db[place].ofail}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Osuccess: #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "bob(##{bob})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "fish").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('exits')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "exit(##{exit})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Dropped objects go to: Limbo(#0)").in_sequence(notify)
			look.do_examine(bob, nil)
			Interface.expects(:do_notify).with(bob, "cheese(#5) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Thing").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[cheese].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Home: Limbo(#0)").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Location: bob(#3)").in_sequence(notify)
			look.do_examine(bob, "cheese")
			Interface.expects(:do_notify).with(bob, "exit(#8) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Exit").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[exit].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Destination: place(#2)").in_sequence(notify)
			look.do_examine(bob, "exit")
			record(exit) {|r| r.merge!( :location => HOME ) }
			Interface.expects(:do_notify).with(bob, "exit(#8) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Exit").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[exit].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('dest-home')).in_sequence(notify)
			look.do_examine(bob, "exit")
			record(place) {|r| r.merge!({ :exits => NOTHING }) }
			record(cheese) {|r| r.merge!({ :next => exit }) }
			record(exit) {|r| r.merge!({ :location => bob }) }
			Interface.expects(:do_notify).with(bob, "exit(#8) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Exit").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[exit].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Carried by: bob(#3)").in_sequence(notify)
			look.do_examine(bob, "exit")
			Interface.expects(:do_notify).with(bob, "place(#2) [bob] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Room").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db[place].description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Fail: #{@db[place].fail}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Success: #{@db[place].succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Ofail: #{@db[place].ofail}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Osuccess: #{@db[place].osucc}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "bob(##{bob})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "anne").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "fish").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('no-exits')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Dropped objects go to: Limbo(#0)").in_sequence(notify)
			look.do_examine(bob, nil)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('can-only-examine-owned')).in_sequence(notify)
			look.do_examine(bob, "anne")
			# Wizards match players
			Interface.expects(:do_notify).with(wizard, "anne(#4) [anne] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Player").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "jam(#7)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "Home: Limbo(#0)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "Location: place(#2)").in_sequence(notify)
			look.do_examine(wizard, "anne")
			# Check flags - just manipulate them to check this code, bit hacky bit covers a case
			record(anne) {|r| r.merge!( :flags => TYPE_PLAYER | WIZARD | STICKY | DARK | LINK_OK | TEMPLE) }
			Interface.expects(:do_notify).with(wizard, "anne(#4) [anne] Key:  ***NOTHING***(#-1) Pennies: 0 Type: Player Flags: WIZARD STICKY DARK LINK_OK TEMPLE").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, Phrasebook.lookup('contents')).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "jam(#7)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "Home: Limbo(#0)").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "Location: place(#2)").in_sequence(notify)
			look.do_examine(wizard, "anne")
		end
		
		def test_do_score
			bob = Player.new(@db).create_player("bob", "pwd")
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(bob, "You have 0 pennies.").in_sequence(notify)
			look.do_score(bob)
			record(bob) {|r| r.merge!({ :pennies => 1 }) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('you-have-a-penny')).in_sequence(notify)
			look.do_score(bob)
		end

		def test_do_inventory
			limbo = 0
			bob = Player.new(@db).create_player("bob", "pwd")
			cheese = @db.add_new_record
			fish = @db.add_new_record
			record(bob) {|r| r.merge!( :contents => NOTHING ) }

			# With nothing
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('carrying-nothing')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have 0 pennies.").in_sequence(notify)
			look.do_inventory(bob)
			
			# Now hold some things
			record(fish) {|r| r.merge!({ :name => "fish", :location => bob, :description => "slimy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => fish, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :pennies => 100 ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('carrying')).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese(#1)").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "fish(#2)").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "You have 100 pennies.").in_sequence(notify)
			look.do_inventory(bob)
		end
		
		def test_do_find
			@db = Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new(@db).create_player("bob", "pwd")
			anne = Player.new(@db).create_player("anne", "pwd")
			cheese = @db.add_new_record
			fish = @db.add_new_record
			jam = @db.add_new_record
			exit = @db.add_new_record
			record(place) {|r| r.merge!({:location => limbo, :name => "place", :description => "yellow", :succ=>"yippee", :fail => "shucks", :osucc => "ping", :ofail => "darn", :contents => bob, :flags => TYPE_ROOM, :exits => exit }) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			record(fish) {|r| r.merge!({ :name => "fish", :location => place, :description => "slimy", :flags => TYPE_THING, :owner => anne, :next => wizard, :exits => limbo }) }
			record(jam) {|r| r.merge!({ :name => "jam", :location => anne, :description => "red", :flags => TYPE_THING, :owner => anne, :next => NOTHING, :exits => limbo }) }
			record(bob) {|r| r.merge!( :contents => cheese, :location => place, :next => anne ) }
			record(anne) {|r| r.merge!( :contents => jam, :location => place, :next => fish ) }
			record(exit) {|r| r.merge!( :location => place, :name => "exit", :description => "long", :flags => TYPE_EXIT, :owner => bob, :next => NOTHING ) }
			
			look = TinyMud::Look.new(@db)
			notify = sequence('notify')
			# Find without enough money!
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('too-poor')).in_sequence(notify)
			look.do_find(bob, "place")
			# Find on an exit (shouldn't)
			record(bob) {|r| r.merge!( :pennies => LOOKUP_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('end-of-list')).in_sequence(notify)
			look.do_find(bob, "exit")
			# Find on someone (do not control)
			record(bob) {|r| r.merge!( :pennies => LOOKUP_COST ) }
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('end-of-list')).in_sequence(notify)
			look.do_find(bob, "anne")
			# Find on something we control
			record(bob) {|r| r.merge!( :pennies => LOOKUP_COST ) }
			Interface.expects(:do_notify).with(bob, "cheese(##{cheese})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, Phrasebook.lookup('end-of-list')).in_sequence(notify)
			look.do_find(bob, "cheese")
		end
    end
end
