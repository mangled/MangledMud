require_relative 'helpers'
require_relative 'create'
require_relative 'help'
require_relative 'look'
require_relative 'match'
require_relative 'move'
require_relative 'player'
require_relative 'predicates'
require_relative 'rob'
require_relative 'set'
require_relative 'speech'
require_relative 'utils'
require_relative 'wiz'

module TinyMud
  class Game
    include Helpers

    attr_reader :shutdown

    # To control penny checks and general random choices (via stubbing)
    def Game.do_rand()
      return rand(0x7FFFFFFF)
    end

    def initialize(db, dumpfile, notifier)
      @db = db
      @dumpfile = dumpfile
      @notifier = notifier
      @epoch = 0
      @shutdown = false;

      # We may not use all of these here...
      @create = Create.new(db, notifier)
      @help = Help.new(db, notifier)
      @look = Look.new(db, notifier)
      @match = Match.new(db, notifier)
      @move = Move.new(@db, notifier)
      @player = Player.new(db, notifier)
      @predicates = Predicates.new(db, notifier)
      @rob = Rob.new(db, notifier)
      @set = Set.new(db, notifier)
      @speech = Speech.new(db, notifier)
      @utils = Utils.new(db)
      @wiz = Wiz.new(db, notifier)

      # Set up command handlers
      @commands = {
        "@chown"    => ->(p, a, b) { @set.do_chown(p, a, b) },
        "@create"   => ->(p, a, b) { @create.do_create(p, a, b.to_i) },
        "@describe" => ->(p, a, b) { @set.do_describe(p, a, b) },
        "@dig"      => ->(p, a, b) { @create.do_dig(p, a) },
        "drop"      => ->(p, a, b) { @move.do_drop(p, a) },
        "@dump"     => ->(p, a, b) { do_dump(p) },
        "examine"   => ->(p, a, b) { @look.do_examine(p, a) },
        "@fail"     => ->(p, a, b) { @set.do_fail(p, a, b) },
        "@find"     => ->(p, a, b) { @look.do_find(p, a) },
        "@force"    => ->(p, a, b) { @wiz.do_force(self, p, a, b) },
        "get"       => ->(p, a, b) { @move.do_get(p, a) },
        "give"      => ->(p, a, b) { @rob.do_give(p, a, b.to_i) },
        "goto"      => ->(p, a, b) { @move.do_move(p, a) },
        "gripe"     => ->(p, a, b) { @speech.do_gripe(p, a, b) },
        "help"      => ->(p, a, b) { @help.do_help(p) },
        "inventory" => ->(p, a, b) { @look.do_inventory(p) },
        "kill"      => ->(p, a, b) { @rob.do_kill(p, a, b.to_i) },
        "@link"     => ->(p, a, b) { @create.do_link(p, a, b) },
        "@lock"     => ->(p, a, b) { @set.do_lock(p, a, b) },
        "look"      => ->(p, a, b) { @look.do_look_at(p, a) },
        "move"      => ->(p, a, b) { @move.do_move(p, a) },
        "@name"     => ->(p, a, b) { @set.do_name(p, a, b) },
        "news"      => ->(p, a, b) { @help.do_news(p) },
        "@ofail"    => ->(p, a, b) { @set.do_ofail(p, a, b) },
        "@open"     => ->(p, a, b) { @create.do_open(p, a, b) },
        "@osuccess" => ->(p, a, b) { @set.do_osuccess(p, a, b) },
        "page"      => ->(p, a, b) { @speech.do_page(p, a) },
        "@password" => ->(p, a, b) { @player.change_password(p, a, b) },
        "read"      => ->(p, a, b) { @look.do_look_at(p, a) },
        "rob"       => ->(p, a, b) { @rob.do_rob(p, a) },
        "say"       => ->(p, a, b) { @speech.do_say(p, a, b) },
        "score"     => ->(p, a, b) { @look.do_score(p) },
        "@set"      => ->(p, a, b) { @set.do_set(p, a, b) },
        "@shutdown" => ->(p, a, b) { do_shutdown(p) },
        "@stats"    => ->(p, a, b) { @wiz.do_stats(p, a) },
        "@success"  => ->(p, a, b) { @set.do_success(p, a, b) },
        "take"      => ->(p, a, b) { @move.do_get(p, a) },
        "@teleport" => ->(p, a, b) { @wiz.do_teleport(p, a, b) },
        "throw"     => ->(p, a, b) { @move.do_drop(p, a) },
        "@toad"     => ->(p, a, b) { @wiz.do_toad(p, a) },
        "@unlink"   => ->(p, a, b) { @set.do_unlink(p, a) },
        "@unlock"   => ->(p, a, b) { @set.do_unlock(p, a) },
        "@wall"     => ->(p, a, b) { @speech.do_wall(p, a, b) }
      }

      # Setup signal handlers
      # trap("INT") { urls_to_crawl.kill(true) }
      # signal(SIGALRM, alarm_handler);
      # signal(SIGHUP, alarm_handler);
      # signal(SIGCHLD, reaper);
      # alarm_triggered = 0;
      # alarm(DUMP_INTERVAL);
    end

#void set_signals()
#{
#    /* we don't care about SIGPIPE, we notice it in select() and write() */
#    signal (SIGPIPE, SIG_IGN);
#
#    /* standard termination signals */
#    signal (SIGINT, bailout);
#    signal (SIGTERM, bailout);
#
#    /* catch these because we might as well */
#    signal (SIGQUIT, bailout);
#    signal (SIGILL, bailout);
#    signal (SIGTRAP, bailout);
#    signal (SIGIOT, bailout);
##if !defined linux
#    signal (SIGEMT, bailout);
##endif
#    signal (SIGFPE, bailout);
#    signal (SIGBUS, bailout);
#    signal (SIGSEGV, bailout);
#    signal (SIGSYS, bailout);
#    signal (SIGTERM, bailout);
#    signal (SIGXCPU, bailout);
#    signal (SIGXFSZ, bailout);
#    signal (SIGVTALRM, bailout);
#    signal (SIGUSR2, bailout);
#
#    /* status dumper (predates "WHO" command) */
#    signal (SIGUSR1, dump_status);
#}

#void bailout(int sig)
#{
#    char message[1024];
#    
#    sprintf (message, "BAILOUT: caught signal %d", sig);
#    panic(message);
#    _exit (7);
#    return;
#}

#void panic(const char *message)
#{
#    char panicfile[2048];
#    FILE *f;
#    int i;
#
#    fprintf(stderr, "PANIC: %s\n", message);
#
#    /* turn off signals */
#    for(i = 0; i < NSIG; i++) {
#	signal(i, SIG_IGN);
#    }
#
#    /* shut down interface */
#    emergency_shutdown();
#
#    /* dump panic file */
#    sprintf(panicfile, "%s.PANIC", dumpfile);
#    if((f = fopen(panicfile, "w")) == NULL) {
#	perror("CANNOT OPEN PANIC FILE, YOU LOSE:");
#	_exit(135);
#    } else {
#	fprintf(stderr, "DUMPING: %s\n", panicfile);
#	db_write(f);
#	fclose(f);
#	fprintf(stderr, "DUMPING: %s (done)\n", panicfile);
#	_exit(136);
#    }
#}

    def do_shutdown(player)
        if (is_wizard(player))
          $stderr.puts "SHUTDOWN: by #{@db[player].name}(#{player})"
          @shutdown = true
        else
          @notifier.do_notify(player, Phrasebook.lookup('delusional'))
        end
    end

    def do_dump(player)
      puts "**** do_dump - This is non-functional, we need the networking code in place..."
      if (is_wizard(player))
        alarm_triggered = 1
        @notifier.do_notify(player, Phrasebook.lookup('dumping'))
      else
        @notifier.do_notify(player, Phrasebook.lookup('sorry-no-dump'))
      end
    end

    def dump_database()
        @epoch = @epoch + 1
        $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}#"
        dump_database_internal(@dumpfile)
        $stderr.puts "DUMPING: #{@dumpfile}.##{@epoch}# (done)"
    end

    # Todo: This code needs to handle disk errors - It should probably be private too
    def dump_database_internal(filename)
      @epoch = @epoch + 1
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

    def process_command(player, command)
      # We need to define a more ruby like way for killing the connection
      # if (command == 0) abort()
  
      # robustify player 
      if (player < 0 || player >= @db.length || !player?(player))
        $stderr.puts("process_command: bad player #{player}")
        return
      end

      # Check for a nil command
      if (command.nil?)
        $stderr.puts("process_command: bad (nil) command")
        return
      end

      # eat leading and trailing whitespace
      command.strip!()

      # collapse white space
      command.gsub!(/\s+/, " ")

      # Is the command empty now (or previously - implied)?
      if (command.empty?)
        $stderr.puts("process_command: bad (empty) command")
        return
      end

      # check for single-character commands 
      if (command[0] == SAY_TOKEN)
        @speech.do_say(player, command[1..-1], nil)
      elsif (command[0] == POSE_TOKEN)
        @speech.do_pose(player, command[1..-1], nil)
      elsif (@move.can_move(player, command))
        # command is an exact match for an exit 
        @move.do_move(player, command)
      else
        # Todo: Make this a little more readable!
        command =~ /^(\S+)(.*)/
        command = $1

        if command.nil?
          @notifier.do_notify(player, Phrasebook.lookup('huh'))
          return
        end

        arg1 = $2
        arg2 = nil

        unless arg1.nil?
          arg1.strip!
          arg1 = nil if arg1.empty?
        end

        if arg1 and arg1.include?('=')
          args = arg1.split('=')
          arg1 = args[0]
          arg2 = args[1]
        end

        matched_command = @commands.keys.find {|c| c.start_with?(command.downcase()) }
        if matched_command
          @commands[matched_command].call(player, arg1, arg2)
        else
          @notifier.do_notify(player, Phrasebook.lookup('huh'))
        end
      end
    end
  end
end
