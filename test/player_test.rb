require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestPlayer < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = MangledMud::Db.new()
      @notifier = mock()
    end

    def teardown
      @db.free()
    end

    def test_lookup_player
      player = Player.new(@db, @notifier)
      assert_equal(NOTHING, player.lookup_player("sir green nose"))

      @db.add_new_record
      @db.add_new_record
      @db.add_new_record
      record = @db[2]
      record.flags = TYPE_PLAYER
      record.name = "sir green nose"
      @db[2] = record

      assert_equal(2, player.lookup_player("sir green nose"))
      assert_equal(2, player.lookup_player("sir green noSe"))
    end

    def test_connect_player
      player = Player.new(@db, @notifier)
      assert_equal(NOTHING, player.connect_player("name", "password"))

      @db.add_new_record
      @db.add_new_record
      record = @db[1]
      record.flags = TYPE_PLAYER
      record.name = "sir green nose"
      record.password = "fish"
      @db[1] = record

      assert_equal(1, player.connect_player("sir green nose", "fish"))
      assert_equal(NOTHING, player.connect_player("sir green noses", "fish"))
      assert_equal(NOTHING, player.connect_player("sir green nose", "fIsh"))
    end

    def test_create_player
      player = Player.new(@db, @notifier)
      assert_equal(NOTHING, player.create_player("", ""))
      assert_equal(NOTHING, player.create_player("", "pwd"))
      assert_equal(NOTHING, player.create_player(" ", "pwd"))
      assert_equal(NOTHING, player.create_player(4.chr, "pwd"))
      assert_equal(NOTHING, player.create_player("*", "pwd"))
      assert_equal(NOTHING, player.create_player("#", "pwd"))
      assert_equal(NOTHING, player.create_player("me", "pwd"))
      assert_equal(NOTHING, player.create_player("home", "pwd"))
      assert_equal(NOTHING, player.create_player("here", "pwd"))

      @db = minimal()
      player = Player.new(@db, @notifier)

      record = @db[0]
      assert_equal(1, record.contents)
      assert_equal(NOTHING, record.next)

      record = @db[1]
      assert_equal(NOTHING, record.contents)
      assert_equal(NOTHING, record.next)

      assert_equal(2, player.create_player("bob", "pwd"))
      record = @db[2]
      assert_equal("bob", record.name)
      assert_equal(PLAYER_START, record.location)
      assert_equal(PLAYER_START, record.exits)
      assert_equal(2, record.owner)
      assert_equal(TYPE_PLAYER, record.flags)
      assert_equal("pwd", record.password)
      assert_equal(1, record.next)

      record = @db[0]
      assert_equal(2, record.contents)
      assert_equal(NOTHING, record.next)

      record = @db[1]
      assert_equal(NOTHING, record.contents)
      assert_equal(NOTHING, record.next)

      assert_equal(3, player.create_player("jane", "pwdd"))
      record = @db[3]
      assert_equal("jane", record.name)
      assert_equal(PLAYER_START, record.location)
      assert_equal(PLAYER_START, record.exits)
      assert_equal(3, record.owner)
      assert_equal(TYPE_PLAYER, record.flags)
      assert_equal("pwdd", record.password)
      assert_equal(2, record.next)

      record = @db[0]
      assert_equal(3, record.contents)
      assert_equal(NOTHING, record.next)

      record = @db[1]
      assert_equal(NOTHING, record.contents)
      assert_equal(NOTHING, record.next)
    end

    def test_change_password
      player = Player.new(@db, @notifier)
      ref = player.create_player("bob", "pwd")
      @notifier.expects(:do_notify).with(0, Phrasebook.lookup('password-changed'))
      player.change_password(ref, "pwd", "ham")
      @notifier.expects(:do_notify).with(0, Phrasebook.lookup('sorry'))
      player.change_password(ref, "hamy", "cheese")
    end
  end
end
