require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestMatch < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_match_player
			Db.Minimal()
			player_ref = Player.new.create_player("bob", "pwd")
			assert_equal(2, player_ref)
			wizard = 1

			match = Match.new
			match.init_match(wizard, "bob", NOTYPE)
		end
    end
end
