require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestStringUtil < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def test_something
			su = TinyMud::StringUtil.new
			assert_not_nil(su)
		end

		def teardown
			@db.free()
		end
    end
end
