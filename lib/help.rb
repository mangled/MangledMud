require_relative 'constants'

module MangledMud
  
  # Handles reading the current help and news files and writing their content
  # back to the player making the respective request.
  #
  # @version 1.0
  class Help

    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called for each line in the news/help file
    def initialize(notifier)
      @notifier = notifier
    end

    # Notify the player of the current help file contents.
    # Notification is through the notifier provided in the initializer
    #
    # @param [Number] player the database record number for the player
    # @param [String] help_file the filename of the help file
    def do_help(player, help_file)
      spit_file(player, help_file)
    end

    # Notify the player of the current news file contents.
    # Notification is through the notifier provided in the initializer
    #
    # @param [Number] player the database record number for the player
    # @param [String] news_file the filename of the news file
    def do_news(player, news_file)
      spit_file(player, news_file)
    end

    private

    # Open the given filename, callback to the provided notifier
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
