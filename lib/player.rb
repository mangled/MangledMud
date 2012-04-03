require_relative 'constants'

module MangledMud

  # Player class takes care of player's creation, access, and connection.
  #
  # @version 1.0
  class Player

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    # Looks up a player by name, returns their index in the database.
    # @note Currently O(N) time
    # @param [String] player_name the player name to search.
    # @return [Number] the db index of the player with the provided name, or {NOTHING} if the name is not found in the db.
    def lookup_player(player_name)
      return NOTHING if (@db.length() == 0 or player_name.nil?)

      for i in (0..@db.length()-1)
        current_record = @db[i]
        if (((current_record.flags() & TYPE_MASK) == TYPE_PLAYER) && current_record.name && current_record.name().upcase() == player_name.upcase())
          return i
        end
      end
      return NOTHING
    end

    # Checks to see if a player's name and password exists in the database.
    # @param [String] player_name the player's name to search for.
    # @param [String] password the provided password to check against the player name.
    # @return [Number] the db index of the player with provided name if the password matches.  If password does not match or name is not found, {NOTHING} is returned.
    def connect_player(player_name, password)
      player = lookup_player(player_name)

      if (player == NOTHING)
        return NOTHING
      elsif (@db[player].password == password)
        return player
      else
        return NOTHING
      end
    end

    # Creates a player with the given name, and adds player to start room. Name must be valid and not in use.
    # @param [String] player_name the name of the player to create.
    # @param [String] password the password for the new player.
    # @return [Number] the newly created player's db index, or {NOTHING} if the name is unacceptable (determined by {Predicates})
    def create_player(player_name, password)
      if (!Predicates.new(@db, @notifier).ok_player_name(player_name))
        return NOTHING
      else
        player_index = @db.add_new_record()
        player = @db[player_index]

        player.name = player_name
        player.location = PLAYER_START
        player.exits = PLAYER_START
        player.owner = player_index
        player.flags = TYPE_PLAYER
        player.password = password

        # link him to PLAYER_START
        player.next = @db[PLAYER_START].contents
        @db[PLAYER_START].contents = player_index

        return player_index
      end
    end

    # Changes a player's password. Notifies an interface if the password changes or the passwords are not the same.
    # Notifies player of the outcome through the notifier passed during initialization.
    # @param [Number] player_index the player index to change the password for.
    # @param [String] old_password the existing password for the player at specified index.
    # @param [String] new_password the new password for the player at specified index.
    def change_password(player_index, old_password, new_password)
      player = @db[player_index]
      if(old_password != player.password)
        @notifier.do_notify(player_index, Phrasebook.lookup('sorry'))
      elsif(old_password == player.password)
        player.password = new_password
        @notifier.do_notify(player_index, Phrasebook.lookup('password-changed'))
      end
    end
  end
end
