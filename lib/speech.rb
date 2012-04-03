require_relative 'helpers'

module MangledMud
  
  # Holds various methods that handle game mechanics related to speech and communications.
  # @version 1.0
  class Speech
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    # Says provided message to the current room of player, notifying everyone in room through the notifier passed during intialization.
    # @param [Number] index of player speaking in db.
    # @param [String] arg1 the first argument
    # @param [String] arg2 the second argument (if any).
    def do_say(player, arg1, arg2)
      loc = getloc(player)
      return if (loc == NOTHING)

      # notify everybody
      message = reconstruct_message(arg1, arg2)
      @notifier.do_notify(player, Phrasebook.lookup('you-say', message))
      notify_except(@db[loc].contents, player, Phrasebook.lookup('someone-says', @db[player].name, message))
    end

    # Performs a custom action in the room, calling back on the notifier passed into the initializer
    # @param [Number] index of player in db performing action.
    # @param [String] arg1 the first argument
    # @param [String] arg2 the second argument (if any).
    def do_pose(player, arg1, arg2)
      loc = getloc(player)
      return if (loc == NOTHING)

      # notify everybody
      message = reconstruct_message(arg1, arg2)
      notify_except(@db[loc].contents, NOTHING, "#{@db[player].name} #{message}")
    end

    # Broadcasts a message across the entire world, calling back on the notifier passed into the initialize. Also prints to server error stream.
    # @param [Number] player index of player in db performing action.
    # @param [String] arg1 the first argument
    # @param [String] arg2 the second argument (if any).
    def do_wall(player, arg1, arg2)
      if (is_wizard(player))
        message = reconstruct_message(arg1, arg2)
        $stderr.puts("WALL from #{@db[player].name}(#{player}): #{message}")
        message = Phrasebook.lookup('someone-shouts', @db[player].name, message)
        0.upto(@db.length() - 1) {|i| @notifier.do_notify(i, message) if (player?(i)) }
      else
        @notifier.do_notify(player, Phrasebook.lookup('what-wall'))
      end
    end

    # Sends help message from any player to admin, calling back on the notifier passed into the initializer.
    # Also prints to server error stream with additional info (name, location).
    # Typically used when player is having technical issue with world (bug, etc.)
    # @param [Number] player_idindex of player in db performing action.
    # @param [String] arg1 the first argument
    # @param [String] arg2 the second argument (if any).
    def do_gripe(player, arg1, arg2)
      loc = @db[player].location
      message = reconstruct_message(arg1, arg2)
      $stderr.puts("GRIPE from #{@db[player].name}(#{player}) in #{Utils.new(@db).getname(loc)}(#{loc}): #{message}")
      @notifier.do_notify(player, Phrasebook.lookup('complaint-noted'))
    end

    # Spends money to alert a distant player someone is looking to contact them, calling back on the notifier passed into the initializer
    # @param [Number] player index of player in db performing action.
    # @param [String] arg1 the first argument. Should be a valid name of a player.
    def do_page(player, arg1)
      target = Player.new(@db, @notifier).lookup_player(arg1)
      if (!Predicates.new(@db, @notifier).payfor(player, LOOKUP_COST))
        @notifier.do_notify(player, Phrasebook.lookup('too-poor'))
      elsif (target == NOTHING)
        @notifier.do_notify(player, Phrasebook.lookup('unknown-name'))
      else
        message = Phrasebook.lookup('someone-looking-for-you', @db[player].name, @db[@db[player].location].name)
        @notifier.do_notify(target, message)
        @notifier.do_notify(player, Phrasebook.lookup('message-sent'))
      end
    end

    # Helper function to send a notify everyone in a list with a particular message besides one person.
    # Used to maintain perspective.
    # @param [Number] first the index of the first player in the room containing a link to a chain of other players to be notified.
    # @param [Number] exception the db index of the player to ignore.
    # @param [String] the message to send to all players besides ignored player.
    def notify_except(first, exception, msg)
      enum(first).each do |i|
        if (is_player(i) && (i != exception))
          @notifier.do_notify(i, msg)
        end
      end
    end

    private

    # Constructs a string with proper formatting for ease of use with other functions.
    def reconstruct_message(arg1, arg2)
      (arg2 and !arg2.empty?) ? "#{arg1} = #{arg2}" : arg1
    end

  end
end
