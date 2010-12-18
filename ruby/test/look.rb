require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestLook < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_look_room
			Db.Minimal()
			limbo = 0
			wizard = 1
			place = @db.add_new_record
			bob = Player.new.create_player("bob", "pwd")
			cheese = @db.add_new_record
			record(limbo) {|r| r.merge!( :contents => wizard ) }
			record(wizard) {|r| r.merge!( :next => bob ) }
			record(place) {|r| r.merge!({:name => "place", :description => "yellow", :osucc => "ping", :contents => NOTHING, :flags => TYPE_ROOM | LINK_OK, :exits => NOTHING }) }
			record(place) {|r| r.merge!({:fail => "fail", :succ => "success", :ofail => "ofail", :osucc => "osuccess" }) }
			record(bob) {|r| r.merge!( :contents => NOTHING, :location => limbo, :next => NOTHING ) }
			record(cheese) {|r| r.merge!({ :name => "cheese", :location => bob, :description => "wiffy", :flags => TYPE_THING, :owner => bob, :next => NOTHING, :exits => limbo }) }
			
			move = TinyMud::Look.new
			notify = sequence('notify')
			# look when can link to (owns or link ok set) - first link set (see above room flags)
			# Note: player doesn't need to be in the room!
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).osucc}").in_sequence(notify)
			move.look_room(bob, place)
			# Now player controls
			record(place) {|r| r.merge!({ :owner => bob, :flags => TYPE_ROOM }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name} (##{place})").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).osucc}").in_sequence(notify)
			move.look_room(bob, place)
			# Now player doesn't control and no link_ok
			record(place) {|r| r.merge!({ :owner => NOTHING }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).succ).in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).osucc}").in_sequence(notify)
			move.look_room(bob, place)
			# Now create a "key", if the player doesn't have the key we fail
			record(place) {|r| r.merge!({ :key => cheese }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).fail}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).ofail}").in_sequence(notify)
			move.look_room(bob, place)
			# Now bob is the key
			record(place) {|r| r.merge!({ :key => bob }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).osucc}").in_sequence(notify)
			move.look_room(bob, place)
			# Now bob holds the key
			record(place) {|r| r.merge!({ :key => cheese }) }
			record(bob) {|r| r.merge!({ :contents => cheese }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(wizard, "bob #{@db.get(place).osucc}").in_sequence(notify)
			move.look_room(bob, place)
			# Now put bob in the room - Should see the contents!
			record(limbo) {|r| r.merge!( :contents => NOTHING ) }
			record(wizard) {|r| r.merge!( :next => bob ) }
			record(place) {|r| r.merge!({ :contents => wizard }) }
			record(bob) {|r| r.merge!({ :next => cheese }) }
			record(cheese) {|r| r.merge!({ :location => place }) }
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).name}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, @db.get(place).description).in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "#{@db.get(place).succ}").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Contents:").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "Wizard").in_sequence(notify)
			Interface.expects(:do_notify).with(bob, "cheese(##{cheese})").in_sequence(notify)
			move.look_room(bob, place)
		end

		def test_do_look_around
			# This basically has one check then calls Look.look_room!!!
			# Not going to repeat all the look tests (above) again here.
			# Will check the gaurd though - Player @ nothing
			bob = Player.new.create_player("bob", "pwd")
			record(bob) {|r| r.merge!( :location => NOTHING ) }
			move = TinyMud::Look.new
			notify = sequence('notify')
			Interface.expects(:do_notify).never.in_sequence(notify)
			move.do_look_around(bob)
		end

		def test_do_look_at
			# todo
		end

		# MOVE THIS SOMEWHERE - DRY
		def record(i)
			record = @db.get(i)

			args = {}
			args[:name] = record.name
			args[:description] = record.description
			args[:location] = record.location
			args[:contents] = record.contents
			args[:exits] = record.exits
			args[:next] = record.next
			args[:key] = record.key
			args[:fail] = record.fail
			args[:succ] = record.succ
			args[:ofail] = record.ofail
			args[:osucc] = record.osucc
			args[:owner] = record.owner
			args[:pennies] = record.pennies
			args[:flags] = record.flags
			args[:password] = record.password

			yield args

			args.each do |key, value|
				case key
				when :name
					record.name = value
				when :description
					record.description = value
				when :location
					record.location = value
				when :contents
					record.contents = value
				when :exits
					record.exits = value
				when :next
					record.next = value
				when :key
					record.key = value
				when :fail
					record.fail = value
				when :succ
					record.succ = value
				when :ofail
					record.ofail = value
				when :osucc
					record.osucc = value
				when :owner
					record.owner = value
				when :pennies
					record.pennies = value
				when :flags
					record.flags = value
				when :password
					record.password = value
				else
					raise("Record - unknown key #{key} with #{value}")
				end
			end

			@db.put(i, record)
		end
    end
end
