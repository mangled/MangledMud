require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestUtils < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_create
			utils = Utils.new
		end
    end
end
