require_relative 'helpers'

module MangledMud

  # Handles applying values to {Db} {Record}'s
  #
  # @version 1.0
  class Set
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
      @match = Match.new(@db, notifier)
      @predicates = Predicates.new(@db, notifier)
      @player = Player.new(@db, notifier)
    end

    # Changes the name of something, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object to rename
    # @param [String] newname the new name to be given to the object (for players a password must also be provided)
    def do_name(player, name, newname)

      thing = match_controlled(player, name)

      if (thing != NOTHING)
        if (newname.nil? or newname.empty?) # check for bad name
          @notifier.do_notify(player, Phrasebook.lookup('what-name'))
          return
        end

        # check for renaming a player
        if (is_player(thing))
          m = newname.match(/([[:graph:]]+)\s+([[:graph:]]+)/)
          newname = (m and m[1]) ? m[1] : nil
          player_password = (m and m[2]) ? m[2] : nil

          # check for null password
          if (player_password.nil?)
            @notifier.do_notify(player, Phrasebook.lookup('specify-a-password'))
            @notifier.do_notify(player, Phrasebook.lookup('help-player-password'))
            return
          elsif (player_password != @db[thing].password)
            @notifier.do_notify(player, Phrasebook.lookup('bad-password'))
            return
          elsif (!@predicates.payfor(player, LOOKUP_COST) || !@predicates.ok_player_name(newname))
            @notifier.do_notify(player, Phrasebook.lookup('bad-player-name'))
            return
          end
        else # A thing
          if (!@predicates.ok_name(newname))
            @notifier.do_notify(player, Phrasebook.lookup('not-a-reasonable-name'))
            return
          end
        end

        # everything ok, change the name
        @db[thing].name = newname
        @notifier.do_notify(player, Phrasebook.lookup('name-set'))
      end
    end

    # Change the description of a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose description is being changed
    # @param [String] description the new description
    # @see Record#description
    def do_describe(player, name, description)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].description = description
        @notifier.do_notify(player, Phrasebook.lookup('desc-set'))
      end
    end

    # Change the fail message for a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose fail message is being changed
    # @param [String] message the new message
    # @see Record#fail
    def do_fail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].fail = message
        @notifier.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end

    # Change the success message for a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose success message is being changed
    # @param [String] message the new message
    # @see Record#succ
    def do_success(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].succ = message
        @notifier.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end

    # Change the external success message for a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose external success message is being changed
    # @param [String] message the new message
    # @see Record#osucc
    def do_osuccess(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].osucc = message
        @notifier.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end

    # Change the external fail message for a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose external fail message is being changed
    # @param [String] message the new message
    # @see Record#ofail
    def do_ofail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].ofail = message
        @notifier.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end

    # Lock a thing to a given key, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object to lock
    # @param [String] keyname the key to lock against, example key "!*murf"
    # @see Record#key
    # @see Record#flags
    def do_lock(player, name, keyname)
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()

      thing = @match.match_result()
      case thing
      when NOTHING
        @notifier.do_notify(player, Phrasebook.lookup('dont-see-lock'))
        return
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('which-one-lock'))
        return
      else
        if (!@predicates.controls(player, thing))
          @notifier.do_notify(player, Phrasebook.lookup('bad-lock'))
          return
        end
      end

      # now we know it's ok to lock
      if keyname
        antilock = (keyname[0] == NOT_TOKEN)
        if (antilock)
          keyname = keyname[1..-1]
          keyname.lstrip!() if keyname
        end
      end

      # match keyname
      @match.init_match(player, keyname, TYPE_THING)
      @match.match_neighbor()
      @match.match_possession()
      @match.match_me()
      @match.match_player()
      @match.match_absolute if (is_wizard(player))

      key = @match.match_result()
      case key
      when NOTHING
        @notifier.do_notify(player, Phrasebook.lookup('no-key'))
        return
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('which-key'))
        return
      else
        if (!is_player(key) && !is_thing(key))
          @notifier.do_notify(player, Phrasebook.lookup('bad-key-link'))
          return
        end
      end

      # everything ok, do it
      @db[thing].key = key
      if (antilock)
        @db[thing].flags |= ANTILOCK
        @notifier.do_notify(player, Phrasebook.lookup('anti-locked'))
      else
        @db[thing].flags &= ~ANTILOCK
        @notifier.do_notify(player, Phrasebook.lookup('locked'))
      end
    end

    # Unlock a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object to unlock
    # @see Record#key
    # @see Record#flags
    def do_unlock(player, name)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].key = NOTHING
        @db[thing].flags &= ~ANTILOCK
        @notifier.do_notify(player, Phrasebook.lookup('unlocked'))
      end
    end

    # Unlink a thing, calling back on the notifier passed into the initializer.
    # This only effects exits and rooms
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object to unlink
    # @see Record#location
    def do_unlink(player, name)
      @match.init_match(player, name, TYPE_EXIT)
      @match.match_exit()
      @match.match_here()
      @match.match_absolute() if(is_wizard(player))

      exit = @match.match_result()
      case exit
      when NOTHING
        @notifier.do_notify(player, Phrasebook.lookup('unlink-what'))
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('which-one'))
      else
        if (!@predicates.controls(player, exit))
          @notifier.do_notify(player, Phrasebook.lookup('no-permission'))
        else
          case typeof(exit)
          when TYPE_EXIT
            @db[exit].location = NOTHING
            @notifier.do_notify(player, Phrasebook.lookup('unlinked'))
          when TYPE_ROOM
            @db[exit].location = NOTHING
            @notifier.do_notify(player, Phrasebook.lookup('drop-to-removed'))
          else
            @notifier.do_notify(player, Phrasebook.lookup('cant-unlink-that'))
          end
        end
      end
    end

    # Change ownership of a thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose ownership is being changed
    # @param [String] newobj the new owner's name (a player)
    # @see Record#owner
    def do_chown(player, name, newobj)
      if (!is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('no-permission'))
      else
        @match.init_match(player, name, NOTYPE)
        @match.match_everything()
        thing = @match.noisy_match_result()
        owner = @player.lookup_player(newobj)
        if (thing == NOTHING)
          return
        elsif (owner == NOTHING)
          @notifier.do_notify(player, Phrasebook.lookup('no-player'))
        elsif (player?(thing))
          @notifier.do_notify(player, Phrasebook.lookup('own-self'))
        else
          @db[thing].owner = owner
          @notifier.do_notify(player, Phrasebook.lookup('owner-changed'))
        end
      end
    end

    # Change a flag on thing, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the change
    # @param [String] name the name of the object whose flags are being changed
    # @param [String] flag the name of the flag to change, see {DARK}, {LINK_OK}, {STICKY}, {WIZARD}, {TEMPLE}
    # @see Record#flags
    def do_set(player, name, flag)
      # find thing
      thing = match_controlled(player, name)
      return if (thing == NOTHING)

      # move p past NOT_TOKEN if present
      unless flag.nil?
        p = flag.strip
        p = p[1..-1] if p[0] == NOT_TOKEN
      end

      # identify flag
      f = nil
      if (p.nil? or p.empty?)
        @notifier.do_notify(player, Phrasebook.lookup('specify-a-flag'))
        return
      elsif (p.casecmp("LINK_OK") == 0)
        f = LINK_OK
      elsif (p.casecmp("DARK") == 0)
        f = DARK
      elsif (p.casecmp("STICKY") == 0)
        f = STICKY
      elsif (p.casecmp("WIZARD") == 0)
        f = WIZARD
      elsif (p.casecmp("TEMPLE") == 0)
        f = TEMPLE
      else
        @notifier.do_notify(player, Phrasebook.lookup('unknown-flag'))
        return
      end

      # check for restricted flag
      if (!is_wizard(player) && (f == WIZARD || f == TEMPLE || (f == DARK && !room?(thing))))
        @notifier.do_notify(player, Phrasebook.lookup('no-permission'))
        return
      end

      # check for stupid wizard
      if (f == WIZARD && flag[0] == NOT_TOKEN && thing == player)
        @notifier.do_notify(player, Phrasebook.lookup('cant-be-mortal'))
        return
      end

      # else everything is ok, do the set
      if (flag[0] == NOT_TOKEN)
        # reset the flag
        @db[thing].flags &= ~f
        @notifier.do_notify(player, Phrasebook.lookup('flag-reset'))
      else
        # set the flag
        @db[thing].flags |= f
        @notifier.do_notify(player, Phrasebook.lookup('flag-set'))
      end
    end

    private

    # Check to see if player controls (owns) thing
    def match_controlled(player, name)
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()

      match = @match.noisy_match_result()
      if (match != NOTHING && !@predicates.controls(player, match))
        @notifier.do_notify(player, Phrasebook.lookup('no-permission'))
        NOTHING
      else
        match
      end
    end

  end
end
