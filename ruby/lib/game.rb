require_relative 'helpers'

module TinyMud
  class Game
    include Helpers

    # To control penny checks and general random choices (via stubbing)
    def Game.do_rand()
      return rand(0x7FFFFFFF)
    end

    # These are class level due to the way the original code was structured
    # resulting in this being the easiest way to  "hack" in some control over
    # the "c" static (yes its messy...for now)
    @epoch = 0
    @db_to_dump = nil
    @dump_file_name = nil

    def self.dump_database_to_file(filename)
      @dump_file_name = filename
      self.dump_database
    end

    def self.set_dumpfile_name(filename)
      @dump_file_name = filename
    end

    def self.set_db=(db)
      @db_to_dump = db
    end

    # Todo: This code needs to handle disk errors
    def self.dump_database
      @epoch = @epoch + 1
      $stderr.puts("DUMPING: #{@dump_file_name}.##{@epoch}#")

      # nuke our predecessor
      tmpfile = "#{@dump_file_name}.##{@epoch - 1}#"
      File.delete(tmpfile) if File.exists?(tmpfile)
  
      # Dump current
      tmpfile = "#{@dump_file_name}.##{@epoch}#"
      @db_to_dump.write(tmpfile)

      # Finalize name
      File.rename(tmpfile, @dump_file_name)
  
      $stderr.puts("DUMPING: #{@dump_file_name}.##{@epoch}# (done)")
    end

    def initialize(db)
      @db = db

      # Set-up the hacky access to the db for the tests/regression scripts
      Game.set_db = db

      # We may not use all of these here...
      @create = Create.new(db)
      @help = Help.new(db)
      @look = Look.new(db)
      @match = Match.new(db)
      @move = Move.new(@db)
      @player = Player.new(db)
      @predicates = Predicates.new(db)
      @rob = Rob.new(db)
      @set = Set.new(db)
      @speech = Speech.new(db)
      @utils = Utils.new(db)
      @wiz = Wiz.new(db)

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
    end

    def do_dump(player)
      # This is non-functional, we need the networking code in place...
      if (is_wizard(player))
        # Todo!!!
        Interface.do_notify(player, "Dumping...")
      else
        Interface.do_notify(player, "Sorry, you are in a no dumping zone.")
      end
    end

    def process_command(player, command)
      # We need to define a more ruby like way for killing the connection
      # if (command == 0) abort()
  
      # robustify player 
      if (player < 0 || player >= @db.length || typeof(player) != TYPE_PLAYER)
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
        command =~ /^(\S+)(.*)/
        command = $1
        arg1 = $2
        arg2 = nil
        arg1.strip! unless arg1.nil?
        arg1 = nil if arg1.empty?
        if arg1 and arg1.include?('=')
          args = arg1.split('=')
          arg1 = args[0]
          arg2 = args[1]
        end

        matched_command = @commands.keys.find {|c| c.start_with?(command.downcase()) }
        if matched_command
          @commands[matched_command].call(player, arg1, arg2)
        else
          Interface.do_notify(player, "Huh?  (Type \"help\" for help.)")
        end
      end
    end
  end
end
