require_relative 'constants.rb'

module MangledMud

  # Handles dumping the database
  class Dump

    attr_accessor :alarm_block

    def initialize(db, dumpfile, emergency_shutdown = nil)
      @db = db
      @dumpfile = dumpfile
      @epoch = 0
      @alarm_block = false

      trap("SIGINT") { bailout(emergency_shutdown) }

      start_dump_thread()
    end

    def start_dump_thread()
      @dumper_thread = Thread.new do
        sleep(DUMP_INTERVAL)
        fork_and_dump()
        start_dump_thread()
      end
    end

    def bailout(emergency_shutdown)
      panic(emergency_shutdown, "BAILOUT: caught signal")
      exit(7)
    end

    def panic(emergency_shutdown, message)
      # Kill the dumper thread
      Thread.kill(@dumper_thread)

      $stderr.puts "PANIC: #{message}"

      # Turn off signals
      Signal.list.each {|name, id| trap(name, "SIG_IGN") }

      # shut down interface
      emergency_shutdown.call() if emergency_shutdown

      # dump panic file
      panic_file = "#{@dumpfile}.PANIC"
      begin
        $stderr.puts "DUMPING: #{panic_file}"
        @db.write(panic_file)
        $stderr.puts "DUMPING: #{panic_file} (done)"
        exit(136)
      rescue
        perror("CANNOT OPEN PANIC FILE #{panic_file}, YOU LOSE:")
        exit(135)
      end
    end

    def do_shutdown()
      Thread.kill(@dumper_thread)
    end

    def fork_and_dump()
      @epoch += 1

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
      @epoch += 1
      $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}#"
      dump_database_internal(@dumpfile)
      $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}# (done)"
    end

    def dump_database_internal(filename)
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
