require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha/test_unit'
require_relative 'include'

module MangledMud
  class TestHelp < Test::Unit::TestCase

    def setup
      @notifier = mock()
    end

    def teardown
    end

    def test_do_help
      help = MangledMud::Help.new(@notifier)
      notify = sequence('notify')

      @notifier.expects(:do_notify).with(0, Phrasebook.lookup('sorry-bad-file', "missing-help.txt")).in_sequence(notify)
      help.do_help(0, "missing-help.txt")

      @notifier.expects(:do_notify).with(0, "This is MangledMUD version 1.0, a user-extendible, multi-user adventure game.").in_sequence(notify)
      @notifier.expects(:do_notify).with(0, "Basic commands: ").in_sequence(notify)
      @notifier.expects(:do_notify).with(0, anything()).times(19).in_sequence(notify)
      help.do_help(0, "help.txt")
    end

    def test_do_news
      help = MangledMud::Help.new(@notifier)
      notify = sequence('notify')

      @notifier.expects(:do_notify).with(0, Phrasebook.lookup('sorry-bad-file', "missing-news.txt")).in_sequence(notify)
      help.do_news(0, "missing-news.txt")

      @notifier.expects(:do_notify).with(0, "No news today.").in_sequence(notify)
      @notifier.expects(:do_notify).with(0, "").in_sequence(notify)
      help.do_news(0, "news.txt")
    end
  end
end
