require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestPlayer < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end

		def test_can_link_to
			# where must be valid, the where must be a room, who must either control (own) where or where is LINK_OK
			Db.Minimal()

			# Make a minimal new player - This should be a helper at some point?
			player_ref = Player.new.create_player("bob", "pwd")
			assert_equal(2, player_ref)
			record = @db.get(player_ref)

			pred = Predicates.new
			assert_equal(0, pred.can_link_to(0, -1)) # Where < 0
			assert_equal(0, pred.can_link_to(0, @db.length)) # where > db_top
			assert_equal(0, pred.can_link_to(0, 1)) # where points to non-room (wizard)

			assert_equal(1, pred.can_link_to(1, 0)) # who = Wizard = 1 = controls all
			
			assert_equal(0, pred.can_link_to(player_ref, 0)) # who = "bob" = 2 = controls nothing, limbo no LINK_OK
			record = @db.get(0)
			record.flags = TYPE_ROOM | LINK_OK
			@db.put(0, record)
			assert_equal(1, pred.can_link_to(player_ref, 0)) # who = "bob" = 2 = controls nothing, limbo no LINK_OK

			# Create an object "bob" owns
			obj_ref = @db.add_new_record
			record = @db.get(obj_ref)
			record.owner = player_ref
			record.flags = TYPE_ROOM
			@db.put(obj_ref, record)
			assert_equal(1, pred.can_link_to(player_ref, obj_ref)) # who = "bob" = 2 = controls object

			# Bob doesn't own, but linking is allowed
			record.owner = 1
			record.flags = TYPE_ROOM | LINK_OK
			@db.put(obj_ref, record)
			assert_equal(1, pred.can_link_to(player_ref, obj_ref)) # who = "bob" = 2 = doesn't control object but it allows links
		end
    end
end
