require 'observer'
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

module MangledMud

  # The main game entity, handling routing of textual commands to sub-classes and subsequent processing.
  # Notifications are passed back to all observers via Observable::notify_observers(player_id, message).
  #
  # The class also hides implementation details of higher-level functions such as creating a player.
  # The design is such that you can run the MUD headless by instantiating this class and observing it (but
  # you will need to create valid players, for this reason you may want to consider using the {Session} class instead)
  #
  # @version 1.0
  class Game
    include Helpers
    include Observable

    # Indicates that the game has been shutdown, the "flag" is set through {#process_command} when a wizard shutdowns the game.
    attr_reader :shutdown

    # All random number calls are routed to this (penny checks and general random choices) to allow test stubbing/mocking
    def Game.do_rand()
      return rand(0x7FFFFFFF)
    end

    # @param [Db] db the database instance to use
    # @param [String] dumpfile file path and name
    # @param [String] help_file file path and name
    # @param [String] news_file file path and name
    def initialize(db, dumpfile, help_file, news_file)
      @db = db
      @shutdown = false
      @help_file = help_file
      @news_file = news_file

      @dump = Dump.new(db, dumpfile)
      @create = Create.new(db, self)
      @help = Help.new(self)
      @look = Look.new(db, self)
      @match = Match.new(db, self)
      @move = Move.new(@db, self)
      @player = Player.new(db, self)
      @predicates = Predicates.new(db, self)
      @rob = Rob.new(db, self)
      @set = Set.new(db, self)
      @speech = Speech.new(db, self)
      @utils = Utils.new(db)
      @wiz = Wiz.new(db, self)

      # Set up command handlers, the true/false is grotty, it indicates if a full
      # match should be taken or not...
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
        "help"      => [->(p, a, b) { @help.do_help(p, @help_file) }, false],
        "inventory" => [->(p, a, b) { @look.do_inventory(p) }, false],
        "kill"      => [->(p, a, b) { @rob.do_kill(p, a, b.to_i) }, false],
        "@link"     => [->(p, a, b) { @create.do_link(p, a, b) }, false],
        "@lock"     => [->(p, a, b) { @set.do_lock(p, a, b) }, false],
        "look"      => [->(p, a, b) { @look.do_look_at(p, a) }, false],
        "move"      => [->(p, a, b) { @move.do_move(p, a) }, false],
        "@name"     => [->(p, a, b) { @set.do_name(p, a, b) }, false],
        "news"      => [->(p, a, b) { @help.do_news(p, @news_file) }, true],
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

    # Attempt to connect (login) a player. See {Session} code for usage.
    # @param [String] user the name of the player
    # @param [String] password the player's password
    # @return [Number] the database index of the player or {NOTHING} if the name or password is invalid
    # @see #do_notify
    def connect_player(user, password)
      @player.connect_player(user, password)
    end

    # Attempt to create a new player. See {Session} code for usage.
    # @param [String] user the name of the player
    # @param [String] password the player's password
    # @return [Number] the database index of the new player or {NOTHING} if the name or password is invalid
    # @see #do_notify
    def create_player(user, password)
      @player.create_player(user, password)
    end

    # Cause the database to be dumped to a panic file!
    # @note Do not call (externally) during #process_command as the database could be being accessed. See {Server} code for examples of usage.
    # @param [String] message to write to stderr
    # @return [Boolean] dump status (true indicates success)
    # @see Dump#panic
    def panic(message)
      @dump.panic(message)
    end

    # Cause the database to be dumped to the main dumpfile
    # @note Do not call (externally) during #process_command as the database could be being accessed. See {Server} code for examples of usage.
    # @see Dump#dump_database
    def dump_database()
      @dump.dump_database()
    end

    # Handler for all {#process_command} responses
    #
    # All output gets routed through this method then on to any observers via a call to
    # Observable::notify_observers(player_id, message).
    #
    # Ideally you would pass in an object to each method and chain it down. The current behaviour is a result
    # of the original TinyMUD code structure and a desire not to refactor it too much for the first release.
    # @param [Number] player_id the record number in the current database
    # @param [String] message the message to present to the player
    def do_notify(player_id, message)
      changed
      notify_observers(player_id, message)
    end

    # Main command handler - All commands from players are routed through this and output events
    # sent back to observers. See {#do_notify}
    #
    # @note This checks for a valid player identifier, Session handles the higher level interactions
    # @param [Number] player_id in the current database
    # @param [String] command to invoke
    # @see #do_notify
    # @see Session
    def process_command(player, command)
      raise "Shutdown signalled but still processing commands" if @shutdown

      # robustify player
      if (player < 0 || player >= @db.length || !player?(player))
        $stderr.puts("process_command: bad player #{player}")
        return
      end

      # Check for a nil command - should Huh?
      if (command.nil?)
        $stderr.puts("process_command: bad (nil) command")
        return
      end

      # eat leading and trailing whitespace and any eol's
      command.strip!()
      command.chomp!()

      # collapse white space
      command.gsub!(/\s+/, " ")

      # Is the command empty now (or previously - implied)? - should Huh?
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
        command, arg1, arg2 = parse(command)

        matched_commands = @commands.find_all {|name, cmd| name.start_with?(command.downcase()) }

        if matched_commands.length == 1
          name, cmd = matched_commands[0]
          perform_full_match = cmd[1]
          if !perform_full_match or (name == command.downcase())
              cmd[0].call(player, arg1, arg2)
          else
            do_notify(player, Phrasebook.lookup('huh'))
          end
        else
          do_notify(player, Phrasebook.lookup('huh'))
        end
      end
    end

    private

    # Handles @shutdown command issued from player
    def do_shutdown(player)
      if (is_wizard(player))
        $stderr.puts "SHUTDOWN: by #{@db[player].name}(#{player})"
        @shutdown = true
      else
        do_notify(player, Phrasebook.lookup('delusional'))
      end
    end

    # Handles @dump command issued from player
    def do_dump(player)
      if (is_wizard(player))
        do_notify(player, Phrasebook.lookup('dumping'))
        dump_database()
      else
        do_notify(player, Phrasebook.lookup('sorry-no-dump'))
      end
    end

    # Helper to parse out command strings
    def parse(command)
      # Grab the first non-whitespace text chunk
      command =~ /^(\S+)(.*)/
      command = $1

      if command.nil?
        do_notify(player, Phrasebook.lookup('huh'))
        return
      end

      # There might be some arguments to the command? If so assume there is one
      # and shove it in arg1
      arg1 = $2
      arg2 = nil

      # nil arg1 if it turns out to not exist
      unless arg1.nil?
        arg1.strip!
        arg1 = nil if arg1.empty?
      end

      # If there is an equals in arg1 then split the text between it and arg2
      if arg1 and arg1.include?('=')
        args = arg1.split('=')
        arg1 = args[0]
        arg2 = args[1]
      end

      [command, arg1, arg2]
    end

  end
end
