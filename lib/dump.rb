require_relative 'constants.rb'

module MangledMud

  # Handles dumping the database to disk
  #
  # This code should probably be pushed into the {Db}. It was originally a large file, after refactoring its almost gone!
  #
  # @note The original code forked dumps of the database under certain situations - We have removed this feature, trading less code for a small delay whilst the databse is dumped to disk (some supported o/s's cannot handle forking anyway).
  # @version 1.0
  class Dump

    # @param [Db] db the database to dump
    # @param [String] dumpfile the name of the file to dump to
    def initialize(db, dumpfile)
      @db = db
      @dumpfile = dumpfile
      @epoch = 0
    end

    # Dump the database to the dumpfile provided in the intializer
    #
    # Writes to a temporary file, then replaces the dumpfile if all goes well.
    #
    # @note this lacks exception handling, so rescue file io issues outside...
    def dump_database()
      @epoch += 1

      $stderr.puts("DUMPING: #{@dumpfile}.##{@epoch}#")

      # nuke our predecessor
      tmpfile = "#{@dumpfile}.##{@epoch - 1}#"
      File.delete(tmpfile) if File.exists?(tmpfile)

      # Dump current
      tmpfile = "#{@dumpfile}.##{@epoch}#"
      @db.save(tmpfile)

      # Finalize name
      File.rename(tmpfile, @dumpfile)

      $stderr.puts("DUMPING: #{@dumpfile}.##{@epoch}# (done)")
    end
  end
end
