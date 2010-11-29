require 'rubygems'
require 'test/unit'
require 'db'
require 'player'
require 'mocha'
require 'pp'

module TinyMud
    class TestPlayer < Test::Unit::TestCase
		Nothing = -1
		Type_player = 0x3
		Player_start = 0

		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end

		def test_lookup_player
			player = Player.new
			assert_equal(Nothing, player.lookup_player("sir green nose"))
			
			@db.add_new_record
			@db.add_new_record
			@db.add_new_record
			record = @db.get(2)
			record.flags = Type_player
			record.name = "sir green nose"
			@db.put(2, record)
			
			assert_equal(2, player.lookup_player("sir green nose"))
			assert_equal(2, player.lookup_player("sir green noSe"))
		end

		def test_connect_player
			player = Player.new
			assert_equal(Nothing, player.connect_player("name", "password"))
			
			@db.add_new_record
			@db.add_new_record
			record = @db.get(1)
			record.flags = Type_player
			record.name = "sir green nose"
			record.password = "fish"
			@db.put(1, record)
			
			assert_equal(1, player.connect_player("sir green nose", "fish"))
			assert_equal(Nothing, player.connect_player("sir green noses", "fish"))
			assert_equal(Nothing, player.connect_player("sir green nose", "fIsh"))
		end
		
		def test_create_player
			player = Player.new
			assert_equal(Nothing, player.create_player("", ""))
			assert_equal(Nothing, player.create_player("", "pwd"))
			assert_equal(Nothing, player.create_player("*", "pwd"))
			assert_equal(Nothing, player.create_player("#", "pwd"))
			assert_equal(Nothing, player.create_player("me", "pwd"))
			assert_equal(Nothing, player.create_player("home", "pwd"))
			assert_equal(Nothing, player.create_player("here", "pwd"))
			
			# Add a "start" entry - I think this is needed
			@db.add_new_record
			record = @db.get(0)
			record.contents = 1000
			@db.put(0, record)
			
			assert_equal(1, player.create_player("bob", "pwd"))
			record = @db.get(1)
			assert_equal("bob", record.name)
			assert_equal(Player_start, record.location)
			assert_equal(Player_start, record.exits)
			assert_equal(1, record.owner)
			assert_equal(Type_player, record.flags)
			assert_equal("pwd", record.password)
			assert_equal(1000, record.next)
			
			record = @db.get(0)
			assert_equal(1, record.contents)
			
			assert_equal(2, player.create_player("jane", "pwdd"))
			record = @db.get(2)
			assert_equal("jane", record.name)
			assert_equal(Player_start, record.location)
			assert_equal(Player_start, record.exits)
			assert_equal(2, record.owner)
			assert_equal(Type_player, record.flags)
			assert_equal("pwdd", record.password)
			assert_equal(1, record.next)
			
			record = @db.get(0)
			assert_equal(2, record.contents)
			# THIS IS UNFINISHED - ADD MORE TESTS - RELATED TO PUSH
		end
		
		def test_change_password
			player = Player.new
			ref = player.create_player("bob", "pwd")
			Player.expects(:do_notify).with("Password changed.")
			player.change_password(ref, "pwd", "ham")
			Player.expects(:do_notify).with("Sorry")
			player.change_password(ref, "hamy", "cheese")
		end
    end
end
