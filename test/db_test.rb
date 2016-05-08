require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestDb < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = MangledMud::Db.new()
    end

    def teardown
      @db.free()
    end

    def test_db_starts_empty
      assert_equal(0, @db.length)
      assert_raise(RuntimeError) { @db[0] } # Should really check error message
      assert_raise(RuntimeError) { @db[0] = nil } # Should really check error message
      @db.add_new_record
      assert_raise(RuntimeError) { @db[1] } # Should really check error message
      assert_raise(RuntimeError) { @db[1] = nil } # Should really check error message
    end

    def test_new_record
      @db.add_new_record
      assert_equal(1, @db.length)
    end

    def test_new_record_content
      @db.add_new_record
      record = @db[0]
      assert_equal(nil, record.name)
      assert_equal(nil, record.description)
      assert_equal(nil, record.fail)
      assert_equal(nil, record.succ)
      assert_equal(nil, record.ofail)
      assert_equal(nil, record.osucc)
      assert_equal(nil, record.password)
      assert_equal(NOTHING, record.location)
      assert_equal(NOTHING, record.contents)
      assert_equal(NOTHING, record.exits)
      assert_equal(NOTHING, record.next)
      assert_equal(NOTHING, record.key)
      assert_equal(NOTHING, record.owner)
      assert_equal(0, record.pennies)
      assert_equal(0, record.flags)
    end

    def test_set_record_content
      @db.add_new_record
      record = @db[0]
      record.name = "name"
      assert_equal("name", record.name)
      record.description = "description"
      assert_equal("description", record.description)
      record.location = 0
      assert_equal(0, record.location)
      record.contents = 1
      assert_equal(1, record.contents)
      record.exits = 2
      assert_equal(2, record.exits)
      record.next = 3
      assert_equal(3, record.next)
      record.key = 4
      assert_equal(4, record.key)
      record.fail = "fail"
      assert_equal("fail", record.fail)
      record.succ = "succ"
      assert_equal("succ", record.succ)
      record.ofail = "ofail"
      assert_equal("ofail", record.ofail)
      record.osucc = "osucc"
      assert_equal("osucc", record.osucc)
      record.owner = 5
      assert_equal(5, record.owner)
      record.pennies = 6
      assert_equal(6, record.pennies)
      record.flags = 7
      assert_equal(7, record.flags)
      record.password = "password"
      assert_equal("password", record.password)
      # None of the derived flag methods warrant testing (for now)
    end

    def test_minimal
      @db = minimal()

      assert_equal(2, @db.length)

      record = @db[0]
      assert_equal("Limbo", record.name)
      assert_equal("You are in a dense mist that seems to go on forever. If you drop an object here, or set its home to be here, you probably won't be able to find it again.", record.description)
      assert_equal(NOTHING, record.location)
      assert_equal(1, record.contents)
      assert_equal(NOTHING, record.exits)
      assert_equal(NOTHING, record.next)
      assert_equal(NOTHING, record.key)
      assert_equal(nil, record.fail)
      assert_equal(nil, record.succ)
      assert_equal(nil, record.ofail)
      assert_equal("is briefly visible through the mist.", record.osucc)
      assert_equal(1, record.owner)
      assert_equal(0, record.pennies)
      assert_equal(TYPE_ROOM, record.flags)
      assert_equal(nil, record.password)

      record = @db[1]
      assert_equal("Wizard", record.name)
      assert_equal("You see The Wizard.", record.description)
      assert_equal(0, record.location)
      assert_equal(NOTHING, record.contents)
      assert_equal(0, record.exits)
      assert_equal(NOTHING, record.next)
      assert_equal(NOTHING, record.key)
      assert_equal('"Get an honest job!" snarls the Wizard.', record.fail)
      assert_equal(nil, record.succ)
      assert_equal("foolishly tried to rob the Wizard!", record.ofail)
      assert_equal(nil, record.osucc)
      assert_equal(1, record.owner)
      assert_equal(0, record.pennies)
      assert_equal(TYPE_PLAYER | WIZARD, record.flags)
      assert_equal("potrzebie", record.password)
    end
  end
end

