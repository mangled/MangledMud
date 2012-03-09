require_relative 'constants.rb'

module TinyMud

  # Handles dumping the database
  class Dump

    attr_accessor :alarm_block

    def initialize(db, dumpfile, emergency_shutdown = nil)
      # todo - are all of these used now?
      @db = db
      @dumpfile = dumpfile
      @epoch = 0

      # This is unused at present - It should be renamed, it means
      # game.rb is potentially accessing the db so don't touch it if
      # a signal of less importance occurs. To be honest I'm considering
      # removing the forking etc. as it simplifies code at the expense
      # of introducing a small delay while the db is dumped. It will make
      # the code more portable too. (windows can't fork())
      @alarm_block = false

      trap("SIGINT") { bailout(emergency_shutdown) }

      @dumper_thread = Thread.new do
        sleep(DUMP_INTERVAL)
        fork_and_dump()
      end
    end

    def bailout(emergency_shutdown)
        # todo - add to phrasebook
        panic(emergency_shutdown, "BAILOUT: caught signal")
        exit(7)
    end
  
    def panic(emergency_shutdown, message)
        # Kill the dumper thread
        Thread.kill(@dumper_thread)

        # todo - add to phrasebook
        $stderr.puts "PANIC: #{message}"
    
        # turn off signals - check this!!! Its disabling all
        # I really don't like this!!!! Sanity check it
        Signal.list.each {|name, id| trap(name, "SIG_IGN") }
  
        # shut down interface
        emergency_shutdown.call() if emergency_shutdown

        # dump panic file
        # todo - add to phrasebook
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
        begin
          pid = fork do
            dump_database_internal(@dumpfile)
            exit!(0)
          end
  
          if (pid < 0)
            $stderr.puts "fork_and_dump: fork()"
          else
            Process.detach(pid)
          end
        rescue NotImplementedError => e
          $stderr.puts e
          $stderr.puts "Dumping on main thread instead..."
          dump_database_internal(@dumpfile)
        end

        # restart the dumper
        @dumper_thread = Thread.new do
          sleep(DUMP_INTERVAL)
          fork_and_dump()
        end
    end

    def dump_database()
        @epoch += 1
        $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}#"
        dump_database_internal(@dumpfile)
        $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}# (done)"
    end

    # Todo: This code needs to handle disk errors
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
