require_relative 'helpers'
require_relative 'dump'
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

    def initialize(db, dumpfile, notifier, emergency_shutdown = nil)
      @db = db
      @notifier = notifier
      @shutdown = false
      @alarm_triggered = false

      # todo - pass this in.
      @dump = Dump.new(db, dumpfile, emergency_shutdown)
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
        "@chown"    => [->(p, a, b) { @set.do_chown(p, a, b) }, false],
        "@create"   => [->(p, a, b) { @create.do_create(p, a, b.to_i) }, false],
        "@describe" => [->(p, a, b) { @set.do_describe(p, a, b) }, false],
        "@dig"      => [->(p, a, b) { @create.do_dig(p, a) }, false],
        "drop"      => [->(p, a, b) { @move.do_drop(p, a) }, false],
        "@dump"     => [->(p, a, b) { do_dump(p) }, false],
        "examine"   => [->(p, a, b) { @look.do_examine(p, a) }, false],
        "@fail"     => [->(p, a, b) { @set.do_fail(p, a, b) }, false],
        "@find"     => [->(p, a, b) { @look.do_find(p, a) }, false],
        "@force"    => [->(p, a, b) { @wiz.do_force(self, p, a, b) }, false],
        "get"       => [->(p, a, b) { @move.do_get(p, a) }, false],
        "give"      => [->(p, a, b) { @rob.do_give(p, a, b.to_i) }, false],
        "goto"      => [->(p, a, b) { @move.do_move(p, a) }, false],
        "gripe"     => [->(p, a, b) { @speech.do_gripe(p, a, b) }, false],
        "help"      => [->(p, a, b) { @help.do_help(p) }, false],
        "inventory" => [->(p, a, b) { @look.do_inventory(p) }, false],
        "kill"      => [->(p, a, b) { @rob.do_kill(p, a, b.to_i) }, false],
        "@link"     => [->(p, a, b) { @create.do_link(p, a, b) }, false],
        "@lock"     => [->(p, a, b) { @set.do_lock(p, a, b) }, false],
        "look"      => [->(p, a, b) { @look.do_look_at(p, a) }, false],
        "move"      => [->(p, a, b) { @move.do_move(p, a) }, false],
        "@name"     => [->(p, a, b) { @set.do_name(p, a, b) }, false],
        "news"      => [->(p, a, b) { @help.do_news(p) }, true],
        "@ofail"    => [->(p, a, b) { @set.do_ofail(p, a, b) }, false],
        "@open"     => [->(p, a, b) { @create.do_open(p, a, b) }, false],
        "@osuccess" => [->(p, a, b) { @set.do_osuccess(p, a, b) }, false],
        "page"      => [->(p, a, b) { @speech.do_page(p, a) }, false],
        "@password" => [->(p, a, b) { @player.change_password(p, a, b) }, false],
        "read"      => [->(p, a, b) { @look.do_look_at(p, a) }, false],
        "rob"       => [->(p, a, b) { @rob.do_rob(p, a) }, false],
        "say"       => [->(p, a, b) { @speech.do_say(p, a, b) }, false],
        "score"     => [->(p, a, b) { @look.do_score(p) }, false],
        "@set"      => [->(p, a, b) { @set.do_set(p, a, b) }, false],
        "@shutdown" => [->(p, a, b) { do_shutdown(p) }, false],
        "@stats"    => [->(p, a, b) { @wiz.do_stats(p, a) }, false],
        "@success"  => [->(p, a, b) { @set.do_success(p, a, b) }, false],
        "take"      => [->(p, a, b) { @move.do_get(p, a) }, false],
        "@teleport" => [->(p, a, b) { @wiz.do_teleport(p, a, b) }, false],
        "throw"     => [->(p, a, b) { @move.do_drop(p, a) }, false],
        "@toad"     => [->(p, a, b) { @wiz.do_toad(p, a) }, true],
        "@unlink"   => [->(p, a, b) { @set.do_unlink(p, a) }, false],
        "@unlock"   => [->(p, a, b) { @set.do_unlock(p, a) }, false],
        "@wall"     => [->(p, a, b) { @speech.do_wall(p, a, b) }, false]
      }
    end

    def do_shutdown(player)
        if (is_wizard(player))
          @dump.do_shutdown()
          $stderr.puts "SHUTDOWN: by #{@db[player].name}(#{player})"
          @shutdown = true
        else
          @notifier.do_notify(player, Phrasebook.lookup('delusional'))
        end
    end

    def do_dump(player)
      if (is_wizard(player))
        @alarm_triggered = true
        @notifier.do_notify(player, Phrasebook.lookup('dumping'))
      else
        @notifier.do_notify(player, Phrasebook.lookup('sorry-no-dump'))
      end
    end

    def dump_database()
        # todo - pass the dumper in...
        @dump.dump_database()
    end

    def process_command(player, command)
      # This is a code smell, we could return a state instead.
      raise "Shutdown signalled but still processing commands" if @shutdown

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

      # eat leading and trailing whitespace and any eol's
      command.strip!()
      command.chomp!()

      # collapse white space
      command.gsub!(/\s+/, " ")

      # Is the command empty now (or previously - implied)?
      if (command.empty?)
        $stderr.puts("process_command: bad (empty) command")
        return
      end

      # We could modify the db from here on...
      @dump.alarm_block = true

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

        matched_commands = @commands.find_all {|name, cmd| name.start_with?(command.downcase()) }
        if matched_commands.length == 1
          name, cmd = matched_commands[0]
          if cmd[1]
            if name == command.downcase()
              cmd[0].call(player, arg1, arg2)
            else
              @notifier.do_notify(player, Phrasebook.lookup('huh'))
            end
          else
            cmd[0].call(player, arg1, arg2)
          end
        else
          @notifier.do_notify(player, Phrasebook.lookup('huh'))
        end
      end
      # Db access done, dump if required
      @dump.alarm_block = false
      if @alarm_triggered
        @dump.fork_and_dump()
        @alarm_triggered = false
      end
    end
  end
end
