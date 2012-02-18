require_relative 'helpers'

module TinyMud
  class Set
    include Helpers

    def initialize(db)
      @db = db
      @match = Match.new(@db)
      @predicates = Predicates.new(@db)
      @player = Player.new(@db)
    end

    def do_name(player, name, newname)

      thing = match_controlled(player, name)

      if (thing != NOTHING)
        if (newname.nil? or newname.empty?) # check for bad name
          Interface.do_notify(player, "Give it what new name?")
          return
        end

        # check for renaming a player
        if (@db[thing].player?)
            m = newname.match(/([[:graph:]]+)\s+([[:graph:]]+)/)
            newname = (m and m[1]) ? m[1] : nil
            player_password = (m and m[2]) ? m[2] : nil

            # check for null password
            if (player_password.nil?)
              Interface.do_notify(player, "You must specify a password to change a player name.")
              Interface.do_notify(player, "E.g.: name player = newname password")
              return
            elsif (player_password != @db[thing].password)
              Interface.do_notify(player, "Incorrect password.")
              return
            elsif (!@predicates.payfor(player, LOOKUP_COST) || !@predicates.ok_player_name(newname))
                  Interface.do_notify(player, "You can't give a player that name.")
              return
            end
        else # A thing
            if (!@predicates.ok_name(newname))
              Interface.do_notify(player, "That is not a reasonable name.")
              return
            end
        end
    
        # everything ok, change the name
        @db[thing].name = newname
        Interface.do_notify(player, "Name set.")
      end
    end

    def do_describe(player, name, description)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].description = description
        Interface.do_notify(player, "Description set.")
      end
    end

    def do_fail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].fail = message
        Interface.do_notify(player, "Message set.")
      end
    end
    
    def do_success(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].succ = message
        Interface.do_notify(player, "Message set.")
      end
    end
    
    def do_osuccess(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].osucc = message
        Interface.do_notify(player, "Message set.")
      end
    end
    
    def do_ofail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].ofail = message
        Interface.do_notify(player, "Message set.")
      end
    end
    
    def do_lock(player, name, keyname) 
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()
  
      thing = @match.match_result()
      case thing
        when NOTHING
          Interface.do_notify(player, "I don't see what you want to lock!")
          return
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know which one you want to lock!")
          return
        else
          if (!@predicates.controls(player, thing))
              Interface.do_notify(player, "You can't lock that!")
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
      @match.match_absolute if (@db[player].wizard?)
  
      key = @match.match_result()
      case key
        when NOTHING
          Interface.do_notify(player, "I can't find that key!")
          return
        when AMBIGUOUS
        Interface.do_notify(player, "I don't know which key you want!")
        return
        else
          if (!@db[key].player? && !@db[key].thing?)
              Interface.do_notify(player, "Keys can only be players or things.")
              return
          end
      end
      
      # everything ok, do it
      @db[thing].key = key
      if (antilock)
        @db[thing].flags |= ANTILOCK
        Interface.do_notify(player, "Anti-Locked.")
      else
        @db[thing].flags &= ~ANTILOCK
        Interface.do_notify(player, "Locked.")
      end
    end
  
    def do_unlock(player, name)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].key = NOTHING
        @db[thing].flags &= ~ANTILOCK
        Interface.do_notify(player, "Unlocked.")
      end
    end
    
    def do_unlink(player, name)
      @match.init_match(player, name, TYPE_EXIT)
      @match.match_exit()
      @match.match_here()
      @match.match_absolute() if(@db[player].wizard?)
  
      exit = @match.match_result()
      case exit
        when NOTHING
          Interface.do_notify(player, "Unlink what?")
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know which one you mean!")
        else
          if (!@predicates.controls(player, exit))
              Interface.do_notify(player, "Permission denied.")
          else
            case typeof(exit)
              when TYPE_EXIT
                @db[exit].location = NOTHING
                Interface.do_notify(player, "Unlinked.")
              when TYPE_ROOM
                @db[exit].location = NOTHING
                Interface.do_notify(player, "Dropto removed.")
              else
                Interface.do_notify(player, "You can't unlink that!")
            end
          end
      end
    end

    def do_chown(player, name, newobj)
      if (!@db[player].wizard?)
        Interface.do_notify(player, "Permission denied.")
      else
        @match.init_match(player, name, NOTYPE)
        @match.match_everything()
        thing = @match.noisy_match_result()
        owner = @player.lookup_player(newobj)
        if (thing == NOTHING)
            return
        elsif (owner == NOTHING)
            Interface.do_notify(player, "I couldn't find that player.")
        elsif (typeof(thing) == TYPE_PLAYER)
            Interface.do_notify(player, "Players always own themselves.")
        else
            @db[thing].owner = owner
            Interface.do_notify(player, "Owner changed.")
        end
      end
    end
    
    # Note, we are not using RESTRICTED_BUILDING so did not port
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
        Interface.do_notify(player, "You must specify a flag to set.")
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
        Interface.do_notify(player, "I don't recognized that flag.")
        return
      end

      # check for restricted flag
      if (!@db[player].wizard? && (f == WIZARD || f == TEMPLE || (f == DARK && typeof(thing) != TYPE_ROOM)))
        Interface.do_notify(player, "Permission denied.")
        return
      end
  
      # check for stupid wizard
      if (f == WIZARD && flag[0] == NOT_TOKEN && thing == player)
        Interface.do_notify(player, "You cannot make yourself mortal.")
        return
      end
  
      # else everything is ok, do the set
      if (flag[0] == NOT_TOKEN)
        # reset the flag
        @db[thing].flags &= ~f
        Interface.do_notify(player, "Flag reset.")
      else
        # set the flag
        @db[thing].flags |= f
        Interface.do_notify(player, "Flag set.")
      end
    end

    private

    def match_controlled(player, name)
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()

      match = @match.noisy_match_result()
      if (match != NOTHING && !@predicates.controls(player, match))
        Interface.do_notify(player, "Permission denied.")
        NOTHING
      else
        match
      end
    end

  end
end
