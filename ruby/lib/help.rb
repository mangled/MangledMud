require_relative 'constants'

module TinyMud
  class Help

    def initialize(notifier)
      @notifier = notifier
    end

    def do_help(player, help_file)
      spit_file(player, help_file)
    end

    def do_news(player, news_file)
      spit_file(player, news_file)
    end

    private

    def spit_file(player, filename)
        begin
          IO.foreach(filename) {|line| @notifier.do_notify(player, line.chomp()) }
        rescue Errno::ENOENT => e
          @notifier.do_notify(player, Phrasebook.lookup('sorry-bad-file', filename))
          $stderr.puts("spit_file: #{e}")
        end
    end

  end
end
