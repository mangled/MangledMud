require 'rubygems'
require 'mocha'
require 'test/unit'
require 'defines'
require 'db'
require 'predicates'
require 'pp'

module TinyMud
    class TestPlayer < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end

		def test_can_link_to
			pred = Predicates.new
			#pred.can_link_to(who, where)
			# TODO
			#return(where >= 0 && where < db_top && Typeof(where) == TYPE_ROOM && (controls(who, where) || (db[where].flags & LINK_OK)))
		end
    end
end
