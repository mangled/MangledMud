require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require 'pp'

module TinyMud
    class TestHelp < Test::Unit::TestCase
		
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end
		
		def test_do_help
			help = TinyMud::Help.new
			notify = sequence('notify')
			Interface.expects(:do_notify).with(0, "This is TinyMUD version 1.3, a user-extendible, multi-user adventure game.").in_sequence(notify)
			Interface.expects(:do_notify).with(0, "Basic commands: ").in_sequence(notify)
			help.do_help(0)
		end

		def test_do_news
			help = TinyMud::Help.new
			notify = sequence('notify')
			Interface.expects(:do_notify).with(0, "Sorry, news.txt is broken.  Management has been notified.").in_sequence(notify)
			help.do_news(0)
		end
    end
end
