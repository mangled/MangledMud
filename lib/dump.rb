require_relative 'constants.rb'

module MangledMud

  # Handles dumping the database - The original code forked some of the database dumps
  # we have removed this feature, trading less code for a small delay whilst the databse
  # is dumped (some supported o/s's cannot handle forking anyway).
  class Dump

    def initialize(db, dumpfile)
      @db = db
      @dumpfile = dumpfile
      @epoch = 0
    end

    def dump_database()
      @epoch += 1

      $stderr.puts("DUMPING: #{@dumpfile}.##{@epoch}#")

      # nuke our predecessor
      tmpfile = "#{@dumpfile}.##{@epoch - 1}#"
      File.delete(tmpfile) if File.exists?(tmpfile)

      # Dump current
      tmpfile = "#{@dumpfile}.##{@epoch}#"
      @db.write(tmpfile)

      # Finalize name
      File.rename(tmpfile, @dumpfile)

      $stderr.puts("DUMPING: #{@dumpfile}.##{@epoch}# (done)")
    end

    def panic(message)
      $stderr.puts "PANIC: #{message}"

      # dump panic file
      panic_file = "#{@dumpfile}.PANIC"
      begin
        $stderr.puts "DUMPING: #{panic_file}"
        @db.write(panic_file)
        $stderr.puts "DUMPING: #{panic_file} (done)"
        return 136
      rescue
        perror("CANNOT OPEN PANIC FILE #{panic_file}, YOU LOSE:")
      end
      return 135
    end
  end
end
