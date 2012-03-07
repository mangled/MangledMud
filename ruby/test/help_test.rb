require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'

module TinyMud
    class TestHelp < Test::Unit::TestCase
		
		def setup
			@notifier = mock()
		end

		def teardown
		end

		def test_do_help
			help = TinyMud::Help.new(@notifier)
			notify = sequence('notify')

			@notifier.expects(:do_notify).with(0, Phrasebook.lookup('sorry-bad-file', "missing-help.txt")).in_sequence(notify)
			help.do_help(0, "missing-help.txt")

			@notifier.expects(:do_notify).with(0, "This is TinyMUD version 1.3, a user-extendible, multi-user adventure game.").in_sequence(notify)
			@notifier.expects(:do_notify).with(0, "Basic commands: ").in_sequence(notify)
			@notifier.expects(:do_notify).with(0, anything()).times(21).in_sequence(notify)
			help.do_help(0, "help.txt")
		end

		def test_do_news
			help = TinyMud::Help.new(@notifier)
			notify = sequence('notify')

			@notifier.expects(:do_notify).with(0, Phrasebook.lookup('sorry-bad-file', "missing-news.txt")).in_sequence(notify)
			help.do_news(0, "missing-news.txt")

			@notifier.expects(:do_notify).with(0, "No news today.").in_sequence(notify)
			@notifier.expects(:do_notify).with(0, "").in_sequence(notify)
			help.do_news(0, "news.txt")
		end
    end
end
