require_relative 'helpers'

module MangledMud

  # Handles checking that a player is able to perform an action
  #
  # @version 1.0
  class Predicates
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    # Checks to see if its possible for a player to make a link to a room
    #
    # @param [Number] who the database record number for the player
    # @param [Number] where the database record number for the room (the type of where is checked)
    # @return [Boolean] true indicates can link
    def can_link_to(who, where)
      where >= 0 &&
      where < @db.length &&
      room?(where) &&
      (controls(who, where) || is_link_ok(where))
    end

    # Checks to see if a player can perform an action on a given object type
    #
    # @param [Number] player the database record number for the player
    # @param [Number] thing the database record number for the thing
    # @return [Boolean] true indicates can perform action
    def could_doit(player, thing)
      return false if (!room?(thing) && @db[thing].location == NOTHING)
      return true if ((key = @db[thing].key) == NOTHING)
      status = (player == key || Utils.new(@db).member(key, @db[player].contents))
      return is_antilock(thing) ? !status : status
    end

    # Checks to see if a player can perform an action on a given object type, calling back on the notifier passed into the initializer.
    # This is a noisy (emits textual status) equivalent to {#could_doit}
    #
    # @param [Number] player the database record number for the player
    # @param [Number] thing the database record number for the thing
    # @param [String] default_fail_msg failure message to use if thing doesn't have a fail message set
    # @return [Boolean] true indicates can perform action
    def can_doit(player, thing, default_fail_msg)
      loc = getloc(player)

      return false if (loc == NOTHING)

      if (!could_doit(player, thing))
        # can't do it
        if (@db[thing].fail)
          @notifier.do_notify(player, @db[thing].fail)
        elsif (default_fail_msg)
          @notifier.do_notify(player, default_fail_msg)
        end

        if (@db[thing].ofail)
          Speech.new(@db, @notifier).notify_except(@db[loc].contents, player, "#{@db[player].name} #{@db[thing].ofail}".to_s)
        end
        false
      else
        # can do it
        if (@db[thing].succ)
          @notifier.do_notify(player, @db[thing].succ)
        end

        if (@db[thing].osucc)
          Speech.new(@db, @notifier).notify_except(@db[loc].contents, player, "#{@db[player].name} #{@db[thing].osucc}")
        end
        true
      end
    end

    # Checks if a player can see a given thing in a specified location
    #
    # @param [Number] player the database record number for the player
    # @param [Number] thing the database record number for the thing
    # @param [Boolean] can_see_loc true if the player is able to see the location occupied by thing
    # @return [Boolean] true if the player can see the thing
    def can_see(player, thing, can_see_loc)
      if (player == thing || exit?(thing))
        return false
      elsif can_see_loc
        return !is_dark(thing) || controls(player, thing)
      else
        # can't see loc
        controls(player, thing)
      end
    end

    # Checks to see if a given player controls (owns) something.
    # Wizards control everything, owners control their stuff.
    #
    # @param [Number] who the database record number for the player
    # @param [Number] what the database record number for the object being tested
    # @return [Boolean] true if they control the object
    def controls(who, what)
      what >= 0 &&
      what < @db.length &&
      (is_wizard(who) || who == @db[what].owner)
    end

    # Checks to see if a player can link to a given object (need not be a room)
    #
    # @note this is only used by {Look} and its logic is looks flawed?
    # @param [Number] who the database record number for the player
    # @param [Number] what the database record number for the object being tested
    # @return [Boolean] true if they can link
    def can_link(who, what)
      (exit?(what) && @db[what].location == NOTHING) || controls(who, what)
    end

    # Checks to see if a player can pay a specified number of pennies.
    # Wizards can always pay (they have unlimited amounts of money, lucky them :-))
    #
    # @param [Number] who the database record number for the player
    # @param [Integer] cost the amount of pennies to pay
    # @return [Boolean] true if they can pay (as a side effect if true then the player also loses cost amount of pennies)
    def payfor(who, cost)
      if (is_wizard(who))
        return true
      elsif (@db[who].pennies >= cost)
        @db[who].pennies -= cost
        return true
      else
        return false
      end
    end

    # Checks for a valid generic name, i.e. isn't a reserved word
    #
    # @param [String] name the name to check
    # @return [Boolean] true if an ok name
    def ok_name(name)
      !name.nil? &&
      !name.empty? &&
      (name[0] != 0.chr) &&
      (name[0] != LOOKUP_TOKEN) &&
      (name[0] != NUMBER_TOKEN) &&
      (name != "me") &&
      (name != "home") &&
      (name != "here")
    end

    # Check for a valid player name
    #
    # @param [String] name the name to check
    # @return [Boolean] true if an ok name
    def ok_player_name(name)
      return false if name.nil?
      return false unless ok_name(name)
      return false if name.match(/[^[:graph:]]/)
      return Player.new(@db, @notifier).lookup_player(name) == NOTHING
    end
  end
end
