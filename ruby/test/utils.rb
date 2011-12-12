require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'tinymud'
require_relative 'helpers'
require 'pp'

module TinyMud
    class TestUtils < Test::Unit::TestCase
		
		include TestHelpers
		
		def setup
			@db = TinyMud::Db.new
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

			utils = Utils.new
			# Not in the list - returns the first!
			assert_equal(thing1, utils.remove_first(thing1, 100))
			# First in the list then it skips it
			assert_equal(thing2, utils.remove_first(thing1, thing1))
			# Not first so it's removed from the chain
			assert_equal(thing1, utils.remove_first(thing1, thing2))
			assert_equal(thing3, @db.get(thing1).next)
		end
		
		def test_member
			thing1 = @db.add_new_record
			thing2 = @db.add_new_record
			thing3 = @db.add_new_record
			record(thing1) {|r| r.merge!({ :next => thing2 }) }
			record(thing2) {|r| r.merge!({ :next => thing3 }) }

			utils = Utils.new
			assert_equal(0, utils.member(thing3 + 1, thing1))
			assert_equal(1, utils.member(thing1, thing1))
			assert_equal(1, utils.member(thing2, thing1))
			assert_equal(1, utils.member(thing3, thing1))
			assert_equal(1, utils.member(thing3, thing2))
		end
		
		def test_reverse
			thing1 = @db.add_new_record
			thing2 = @db.add_new_record
			thing3 = @db.add_new_record
			record(thing1) {|r| r.merge!({ :name => "thing1", :next => thing2 }) }
			record(thing2) {|r| r.merge!({ :name => "thing2", :next => thing3 }) }
			record(thing3) {|r| r.merge!({ :name => "thing3", :next => NOTHING }) }
			assert_equal("thing1", @db.get(0).name)
			assert_equal(thing2, @db.get(0).next)
			assert_equal(thing3, @db.get(0).next.next)

			utils = Utils.new
			reversed = utils.reverse(thing1)
			assert_equal(NOTHING, @db.get(thing1).next)
			assert_equal(thing1, @db.get(thing2).next)
			assert_equal(thing2, @db.get(thing3).next)
			assert_equal("thing3", @db.get(reversed).name)
			assert_equal(thing2, @db.get(reversed).next)
			assert_equal(thing1, @db.get(@db.get(reversed).next).next)
		end
		
		def test_getname
			thing1 = @db.add_new_record
			record(thing1) {|r| r.merge!({ :name => "cheese", :location => NOTHING }) }
			utils = Utils.new
			assert_equal("***NOTHING***", utils.getname(NOTHING))
			assert_equal("***HOME***", utils.getname(HOME))
			assert_equal("cheese", utils.getname(thing1))
		end
    end
end
