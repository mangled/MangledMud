require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Game
    include Helpers

    # These are class level due to the way the original code was structured
    # resulting in this being the easiest way to  "hack" in some control over
    # the "c" static (yes its messy...for now)
    @epoch = 0
    @db_to_dump = nil
    @dump_file_name = nil

    def self.dump_database_to_file(filename)
      @dump_file_name = filename
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
      tmpfile = "#{@dump_file_name}.##{epoch - 1}#"
      File.delete(tmpfile) if File.exists?(tmpfile)
  
      # Dump current
      tmpfile = "#{@dump_file_name}.##{epoch}#"
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
    end

    def do_dump(player)
      puts "This is non-functional - fix"
      if (is_wizard(player))
        # Todo!!!
        Interface.do_notify(player, "Dumping...")
      else
        Interface.do_notify(player, "Sorry, you are in a no dumping zone.")
      end
    end

    # Todo- WE REALLY NEED TO break apart this gigantic switch statement
    def do_process_command(player, command)
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
        @speech.do_say(player, command + 1, NULL)
      else if(command[0] == POSE_TOKEN)
        @speech.do_pose(player, command + 1, NULL)
      else if (r_truthify(@move.can_move(player, command)))
        # command is an exact match for an exit 
        @move.do_move(player, command)
      else
        # parse arguments - split out the command and possible arguments
        # Todo- This isn't very robust FIX!
        args = command.split(" ").collect{|i| i.downcase() }
        command = args[0]
        arg1 = args[1]
        arg2 = args[2]
        if (arg2 and arg2 == '=')
          arg2 = args[3]
        end

        case command[0]
          when '@'
            case command[1]
              when 'c'
              when 'C'
                # chown, create
                case command[2]
                    when 'h'
                    when 'H'
                      @set.do_chown(player, arg1, arg2) if Matched("@chown", command)
                    when 'r'
                    when 'R'
                      @create.do_create(player, arg1, atol(arg2)) if Matched("@create", command)
                    else
                      Huh()
                end
              when 'd'
              when 'D'
                # describe, dig, or dump 
                case command[2]
                  when 'e'
                  when 'E'
                    @set.do_describe(player, arg1, arg2) if Matched("@describe", command)
                  when 'i'
                  when 'I'
                    @create.do_dig(player, arg1) if Matched("@dig", command)
                  when 'u'
                  when 'U'
                    do_dump(player) if Matched("@dump", command)
                  else
                    Huh()
                end
              when 'f'
                # fail, find, or force 
                case command[2]
                  when 'a'
                  when 'A'
                    @set.do_fail(player, arg1, arg2) if Matched("@fail", command)
                  when 'i'
                  when 'I'
                    @look.do_find(player, arg1) if Matched("@find", command)
# Todo - Enable?
##ifdef DO_FLUSH
#          when 'l'
#          when 'L'
#            if(string_compare(command, "@flush")) goto bad
#            do_flush(player)
#            break
##endif				# DO_FLUSH 
                  when 'o'
                  when 'O'
                     @wiz.do_force(player, arg1, arg2) if Matched("@force", command)
                  else
                    Huh()
                end
              when 'l'
              when 'L'
                # lock or link 
                case command[2]
                  when 'i'
                  when 'I'
                    @create.do_link(player, arg1, arg2) if Matched("@link", command)
                  when 'o'
                  when 'O'
                    @set.do_lock(player, arg1, arg2) if Matched("@lock", command)
                  else
                    Huh()
                end
              when 'n'
              when 'N'
                @set.do_name(player, arg1, arg2) if Matched("@name", command)
              when 'o'
              when 'O'
                case command[2]
                  when 'f'
                  when 'F'
                    @set.do_ofail(player, arg1, arg2) if Matched("@ofail", command)
                  when 'p'
                  when 'P'
                    @create.do_open(player, arg1, arg2) if Matched("@open", command)
                  when 's'
                  when 'S'
                    @set.do_osuccess(player, arg1, arg2) if Matched("@osuccess", command)
                  else
                    Huh()
                end
              when 'p'
              when 'P'
                do_password(player, arg1, arg2) if Matched("@password", command)
              when 's'
              when 'S'
                # set, shutdown, success 
                case command[2]
                  when 'e'
                  when 'E'
                    @set.do_set(player, arg1, arg2) if Matched("@set", command)
                  when 'h'
                    do_shutdown(player) if Matched("@shutdown", command)
                  when 't'
                  when 'T'
                    @wiz.do_stats(player, arg1) if Matched("@stats", command)
                  when 'u'
                  when 'U'
                    @set.do_success(player, arg1, arg2) if Matched("@success", command)
                  else
                    Huh()
                end
              when 't'
              when 'T'
                case command[2]
                  when 'e'
                  when 'E'
                    @wiz.do_teleport(player, arg1, arg2) if Matched("@teleport", command)
                  when 'o'
                    @wiz.do_toad(player, arg1) if Matched("@toad", command)
                  else
                    Huh()
                end
              when 'u'
              when 'U'
                if command.start_with?("@unli")
                  @set.do_unlink(player, arg1) if Matched("@unlink", command)
                elsif command.start_with?("@unlo")
                  @set.do_unlock(player, arg1) if Matched("@unlock", command)
                else
                  Huh()
                end
              when 'w'
                @speech.do_wall(player, arg1, arg2) if Matched("@wall", command)
            end
          when 'd'
          when 'D'
            @move.do_drop(player, arg1) if Matched("drop", command)
          when 'e'
          when 'E'
            @look.do_examine(player, arg1) if Matched("examine", command)
          when 'g'
          when 'G'
            # get, give, go, or gripe 
            case command[1]
                when 'e'
                when 'E'
                  @move.do_get(player, arg1) if Matched("get", command)
                when 'i'
                when 'I'
                  @rob.do_give(player, arg1, atol(arg2)) if Matched("give", command)
                when 'o'
                when 'O'
                  @move.do_move(player, arg1) if Matched("goto", command)
                when 'r'
                when 'R'
                  @speech.do_gripe(player, arg1, arg2) if Matched("gripe", command)
                else
                  Huh()
            end
          when 'h'
          when 'H'
            @help.do_help(player) if Matched("help", command)
          when 'i'
          when 'I'
            @look.do_inventory(player) if Matched("inventory", command)
          when 'k'
          when 'K'
            @rob.do_kill(player, arg1, atol(arg2)) if Matched("kill", command)
          when 'l'
          when 'L'
            @look.do_look_at(player, arg1) if Matched("look", command)
          when 'm'
          when 'M'
            @move.do_move(player, arg1) if Matched("move", command)
          when 'n'
          when 'N'
            # news 
            @help.do_news(player) if Matched("news")
          when 'p'
          when 'P'
            @speech.do_page(player, arg1) if Matched("page", command)
          when 'r'
          when 'R'
            case command[1]
              when 'e'
              when 'E'
                @look.do_look_at(player, arg1) if Matched("read", command) # undocumented alias for look at 
              when 'o'
              when 'O'
                @rob.do_rob(player, arg1) if Matched("rob", command)
              else
                Huh()
            end
          when 's'
          when 'S'
            # say, "score" 
            case command[1]
              when 'a'
              when 'A'
                @speech.do_say(player, arg1, arg2) if Matched("say", command)
              when 'c'
              when 'C'
                @look.do_score(player) if Matched("score", command)
              else
                Huh()
            end
          when 't'
          when 'T'
            case command[1]
              when 'a'
              when 'A'
                @move.do_get(player, arg1) if Matched("take", command)
              when 'h'
              when 'H'
                @move.do_drop(player, arg1) if Matched("throw", command)
              else
                Huh()
            end
        end
    end

    def Matched(s, cmd)
        Huh(s.downcase().start_with?(cmd.downcase()))
    end

    def Huh(no_huh = false)
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
