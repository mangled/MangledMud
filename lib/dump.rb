require_relative 'constants.rb'

module MangledMud

  # Handles dumping the database to disk
  #
  # This code should probably be pushed into the {Db}. It was originally a large file, after refactoring its almost gone!
  #
  # @note The original code forked dumps of the database under certain situations - We have removed this feature, trading less code for a small delay whilst the databse is dumped to disk (some supported o/s's cannot handle forking anyway).
  # @version 1.0
  class Dump

    # @param [Db] db to dump
    # @param [String] dumpfile the name of the file to dump to
    def initialize(db, dumpfile)
      @db = db
      @dumpfile = dumpfile
      @epoch = 0
    end

    # Dump the database to the dumpfile
    #
    # Produces a temporary dumpfile, replacing the dumpfile if all goes well.
    #
    # @note this could be combined with {#panic}
    # @todo trap exceptions
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

    # Dump the database (directly) to the dumpfile
    #
    # @return [Boolean] dump status (true indicates success)
    def panic(message)
      $stderr.puts "PANIC: #{message}"

      # dump panic file
      panic_file = "#{@dumpfile}.PANIC"
      begin
        $stderr.puts "DUMPING: #{panic_file}"
        @db.write(panic_file)
        $stderr.puts "DUMPING: #{panic_file} (done)"
        true
      rescue
        perror("CANNOT OPEN PANIC FILE #{panic_file}, YOU LOSE:")
      end
      false
    end
  end
end
