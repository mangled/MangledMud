require_relative 'constants.rb'

module TinyMud
  class Help

    def initialize(db)
      @db = db
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
          IO.foreach(filename) {|line| Interface.do_notify(player, line.chomp()) }
        rescue Errno::ENOENT => e
          Interface.do_notify(player, "Sorry, #{filename} is broken.  Management has been notified.")
          $stderr.puts("spit_file: #{e}")
        end
    end

  end
end
