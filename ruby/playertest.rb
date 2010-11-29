require 'rubygems'
require 'test/unit'
require 'db'
require 'player'
require 'pp'

module TinyMud
    class TestPlayer < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
    end
end
