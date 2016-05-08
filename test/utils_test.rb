require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'helpers'

module MangledMud
  class TestUtils < Test::Unit::TestCase

    include TestHelpers

    def setup
      @db = MangledMud::Db.new()
    end

    def teardown
      @db.free()
    end

    def test_remove_first
      thing1 = @db.add_new_record
      thing2 = @db.add_new_record
      thing3 = @db.add_new_record
      record(thing1) {|r| r.merge!({ :next => thing2 }) }
      record(thing2) {|r| r.merge!({ :next => thing3 }) }

      utils = Utils.new(@db)
      # Not in the list - returns the first!
      assert_equal(thing1, utils.remove_first(thing1, 100))
      # First in the list then it skips it
      assert_equal(thing2, utils.remove_first(thing1, thing1))
      # Not first so it's removed from the chain
      assert_equal(thing1, utils.remove_first(thing1, thing2))
      assert_equal(thing3, @db[thing1].next)
    end

    def test_member
      thing1 = @db.add_new_record
      thing2 = @db.add_new_record
      thing3 = @db.add_new_record
      record(thing1) {|r| r.merge!({ :next => thing2 }) }
      record(thing2) {|r| r.merge!({ :next => thing3 }) }

      utils = Utils.new(@db)
      assert_equal(false, utils.member(thing3 + 1, thing1))
      assert_equal(true, utils.member(thing1, thing1))
      assert_equal(true, utils.member(thing2, thing1))
      assert_equal(true, utils.member(thing3, thing1))
      assert_equal(true, utils.member(thing3, thing2))
    end

    def test_reverse
      thing1 = @db.add_new_record
      thing2 = @db.add_new_record
      thing3 = @db.add_new_record
      record(thing1) {|r| r.merge!({ :name => "thing1", :next => thing2 }) }
      record(thing2) {|r| r.merge!({ :name => "thing2", :next => thing3 }) }
      record(thing3) {|r| r.merge!({ :name => "thing3", :next => NOTHING }) }
      assert_equal("thing1", @db[0].name)
      assert_equal(thing2, @db[0].next)
      assert_equal(thing3, @db[0].next.next)

      utils = Utils.new(@db)
      reversed = utils.reverse(thing1)
      assert_equal(NOTHING, @db[thing1].next)
      assert_equal(thing1, @db[thing2].next)
      assert_equal(thing2, @db[thing3].next)
      assert_equal("thing3", @db[reversed].name)
      assert_equal(thing2, @db[reversed].next)
      assert_equal(thing1, @db[@db[reversed].next].next)
    end

    def test_getname
      thing1 = @db.add_new_record
      record(thing1) {|r| r.merge!({ :name => "cheese", :location => NOTHING }) }
      utils = Utils.new(@db)
      assert_equal(Phrasebook.lookup('loc-nothing'), utils.getname(NOTHING))
      assert_equal(Phrasebook.lookup('loc-home'), utils.getname(HOME))
      assert_equal("cheese", utils.getname(thing1))
    end
  end
end
