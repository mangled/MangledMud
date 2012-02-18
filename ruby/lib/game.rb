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
      Db.write(tmpfile)

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
    end

    def do_dump(player)
      # This is non-functional, we need the networking code in place...
      if (@db[player].wizard?)
        # Todo!!!
        Interface.do_notify(player, "Dumping...")
      else
        Interface.do_notify(player, "Sorry, you are in a no dumping zone.")
      end
    end

    # Todo- WE REALLY NEED TO break apart this gigantic switch statement
    def process_command(player, command)
      # We need to define a more ruby like way for killing the connection
      # if (command == 0) abort()
  
      # robustify player 
      if (player < 0 || player >= @db.length || typeof(player) != TYPE_PLAYER)
        $stderr.puts("process_command: bad player #{player}")
        return
      end

      # Consider a replacement to this
      ##ifdef LOG_COMMANDS
      #    fprintf(stderr, "COMMAND from %s(%d) in %s(%d): %s\n",
      #        getname(player), player,
      #        getname(db[player].location),
      #        db[player].location,
      #        command)
      ##endif # LOG_COMMANDS

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
      elsif(command[0] == POSE_TOKEN)
        @speech.do_pose(player, command[1..-1], nil)
      elsif (@move.can_move(player, command))
        # command is an exact match for an exit 
        @move.do_move(player, command)
      else
        # Todo: This parsing code is rubbish, fix :-)
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

        case command[0].downcase
          when '@'
            case command[1].downcase
              when 'c'
                # chown, create
                case command[2].downcase
                    when 'h'
                      @set.do_chown(player, arg1, arg2) if Matched("@chown", command, player)
                    when 'r'
                      @create.do_create(player, arg1, arg2.to_i) if Matched("@create", command, player)
                    else
                      Huh(player)
                end
              when 'd'
                # describe, dig, or dump 
                case command[2].downcase
                  when 'e'
                    @set.do_describe(player, arg1, arg2) if Matched("@describe", command, player)
                  when 'i'
                    @create.do_dig(player, arg1) if Matched("@dig", command, player)
                  when 'u'
                    do_dump(player) if Matched("@dump", command, player)
                  else
                    Huh(player)
                end
              when 'f'
                # fail, find, or force 
                case command[2].downcase
                  when 'a'
                    @set.do_fail(player, arg1, arg2) if Matched("@fail", command, player)
                  when 'i'
                    @look.do_find(player, arg1) if Matched("@find", command, player)
                    # Todo - Enable?
                    ##ifdef DO_FLUSH
                    #          when 'l'
                    #          when 'L'
                    #            if(string_compare(command, "@flush")) goto bad
                    #            do_flush(player)
                    #            break
                    ##endif
                  when 'o'
                     @wiz.do_force(self, player, arg1, arg2) if Matched("@force", command, player)
                  else
                    Huh(player)
                end
              when 'l'
                # lock or link 
                case command[2].downcase
                  when 'i'
                    @create.do_link(player, arg1, arg2) if Matched("@link", command, player)
                  when 'o'
                    @set.do_lock(player, arg1, arg2) if Matched("@lock", command, player)
                  else
                    Huh(player)
                end
              when 'n'
                @set.do_name(player, arg1, arg2) if Matched("@name", command, player)
              when 'o'
                case command[2].downcase
                  when 'f'
                    @set.do_ofail(player, arg1, arg2) if Matched("@ofail", command, player)
                  when 'p'
                    @create.do_open(player, arg1, arg2) if Matched("@open", command, player)
                  when 's'
                    @set.do_osuccess(player, arg1, arg2) if Matched("@osuccess", command, player)
                  else
                    Huh(player)
                end
              when 'p'
                @player.change_password(player, arg1, arg2) if Matched("@password", command, player)
              when 's'
                # set, shutdown, success 
                case command[2].downcase
                  when 'e'
                    @set.do_set(player, arg1, arg2) if Matched("@set", command, player)
                  when 'h'
                    do_shutdown(player) if Matched("@shutdown", command, player)
                  when 't'
                    @wiz.do_stats(player, arg1) if Matched("@stats", command, player)
                  when 'u'
                    @set.do_success(player, arg1, arg2) if Matched("@success", command, player)
                  else
                    Huh(player)
                end
              when 't'
                case command[2].downcase
                  when 'e'
                    @wiz.do_teleport(player, arg1, arg2) if Matched("@teleport", command, player)
                  when 'o'
                    @wiz.do_toad(player, arg1) if Matched("@toad", command, player)
                  else
                    Huh(player)
                end
              when 'u'
                if command.start_with?("@unli")
                  @set.do_unlink(player, arg1) if Matched("@unlink", command, player)
                elsif command.start_with?("@unlo")
                  @set.do_unlock(player, arg1) if Matched("@unlock", command, player)
                else
                  Huh(player)
                end
              when 'w'
                @speech.do_wall(player, arg1, arg2) if Matched("@wall", command, player)
              else
                Huh(player)
            end
          when 'd'
            @move.do_drop(player, arg1) if Matched("drop", command, player)
          when 'e'
            @look.do_examine(player, arg1) if Matched("examine", command, player)
          when 'g'
            # get, give, go, or gripe 
            case command[1].downcase
                when 'e'
                  @move.do_get(player, arg1) if Matched("get", command, player)
                when 'i'
                  @rob.do_give(player, arg1, arg2.to_i) if Matched("give", command, player)
                when 'o'
                  @move.do_move(player, arg1) if Matched("goto", command, player)
                when 'r'
                  @speech.do_gripe(player, arg1, arg2) if Matched("gripe", command, player)
                else
                  Huh(player)
            end
          when 'h'
            @help.do_help(player) if Matched("help", command, player)
          when 'i'
            @look.do_inventory(player) if Matched("inventory", command, player)
          when 'k'
            @rob.do_kill(player, arg1, arg2.to_i) if Matched("kill", command, player)
          when 'l'
            @look.do_look_at(player, arg1) if Matched("look", command, player)
          when 'm'
            @move.do_move(player, arg1) if Matched("move", command, player)
          when 'n'
            # news 
            @help.do_news(player) if Matched("news", command, player)
          when 'p'
            @speech.do_page(player, arg1) if Matched("page", command, player)
          when 'r'
            case command[1].downcase
              when 'e'
                @look.do_look_at(player, arg1) if Matched("read", command, player) # undocumented alias for look at 
              when 'o'
                @rob.do_rob(player, arg1) if Matched("rob", command, player)
              else
                Huh(player)
            end
          when 's'
            # say, "score" 
            case command[1].downcase
              when 'a'
                @speech.do_say(player, arg1, arg2) if Matched("say", command, player)
              when 'c'
                @look.do_score(player) if Matched("score", command, player)
              else
                Huh(player)
            end
          when 't'
            case command[1].downcase
              when 'a'
                @move.do_get(player, arg1) if Matched("take", command, player)
              when 'h'
                @move.do_drop(player, arg1) if Matched("throw", command, player)
              else
                Huh(player)
            end
        else
          Huh(player)
        end
      end
    end

    def Matched(s, cmd, player)
        Huh(player, s.downcase().start_with?(cmd.downcase()))
    end

    def Huh(player, no_huh = false)
      Interface.do_notify(player, "Huh?  (Type \"help\" for help.)") unless no_huh
      # Todo - Consider a replacement
      ##ifdef LOG_FAILED_COMMANDS
      #if(!controls(player, db[player].location)) {
      #  fprintf(stderr, "HUH from %s(%d) in %s(%d)[%s]: %s %s\n",
      #      getname(player), player,
      #      getname(db[player].location),
      #      db[player].location,
      #      getname(db[db[player].location].owner),
      #      command,
      #      reconstruct_message(arg1, arg2))
      #}
      #ifdef LOG_FAILED_COMMANDS
      no_huh
    end

  end
end
