require_relative 'constants'

module TinyMud
  class Help

    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    def do_help(player)
      spit_file(player, HELP_FILE)
    end
    
    def do_news(player)
      spit_file(player, NEWS_FILE)
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
