require_relative 'constants.rb'

module MangledMud

  # Handles dumping the database
  class Dump

    attr_accessor :alarm_block

    def initialize(db, dumpfile)
      @db = db
      @dumpfile = dumpfile
      @epoch = 0
      @alarm_block = false
      start_dump_thread()
    end

    def start_dump_thread()
      @dumper_thread = Thread.new do
        sleep(DUMP_INTERVAL)
        fork_and_dump()
        start_dump_thread()
      end
    end

    def panic(message)
      Thread.kill(@dumper_thread)

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

    def do_shutdown()
      Thread.kill(@dumper_thread)
    end

    def fork_and_dump()
      $stderr.puts "CHECKPOINTING: #{@dumpfile}.##{@epoch}#"
      if Process.respond_to?(:fork)
        pid = fork do
          dump_database_internal(@dumpfile)
          exit!(0)
        end

        if (pid < 0)
          $stderr.puts "fork_and_dump: fork()"
        else
          Process.detach(pid)
        end
      else
        $stderr.puts "Fork unavailable so dumping on main thread instead..."
        $stderr.puts "Warning: Currently executing a command on main thread - Dump could be corrupted!" if @alarm_block
        dump_database_internal(@dumpfile)
      end
    end

    def dump_database()
      dump_database_internal(@dumpfile)
    end

    def dump_database_internal(filename)
      @epoch += 1

      $stderr.puts("DUMPING: #{filename}.##{@epoch}#")

      # nuke our predecessor
      tmpfile = "#{filename}.##{@epoch - 1}#"
      File.delete(tmpfile) if File.exists?(tmpfile)

      # Dump current
      tmpfile = "#{filename}.##{@epoch}#"
      @db.write(tmpfile)

      # Finalize name
      File.rename(tmpfile, filename)

      $stderr.puts("DUMPING: #{filename}.##{@epoch}# (done)")
    end
  end
end
