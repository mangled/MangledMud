require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestGame < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def test_something
			assert_not_nil(TinyMud::Game.new)
		end

		def teardown
			@db.free()
		end
    end
end
