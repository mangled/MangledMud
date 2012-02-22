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
          Interface.do_notify(player, Phrasebook.lookup('what-name'))
          return
        end

        # check for renaming a player
        if (is_player(thing))
            m = newname.match(/([[:graph:]]+)\s+([[:graph:]]+)/)
            newname = (m and m[1]) ? m[1] : nil
            player_password = (m and m[2]) ? m[2] : nil

            # check for null password
            if (player_password.nil?)
              Interface.do_notify(player, Phrasebook.lookup('specify-a-password'))
              Interface.do_notify(player, Phrasebook.lookup('help-player-password'))
              return
            elsif (player_password != @db[thing].password)
              Interface.do_notify(player, Phrasebook.lookup('bad-password'))
              return
            elsif (!@predicates.payfor(player, LOOKUP_COST) || !@predicates.ok_player_name(newname))
                  Interface.do_notify(player, Phrasebook.lookup('bad-player-name'))
              return
            end
        else # A thing
            if (!@predicates.ok_name(newname))
              Interface.do_notify(player, Phrasebook.lookup('not-a-reasonable-name'))
              return
            end
        end
    
        # everything ok, change the name
        @db[thing].name = newname
        Interface.do_notify(player, Phrasebook.lookup('name-set'))
      end
    end

    def do_describe(player, name, description)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].description = description
        Interface.do_notify(player, Phrasebook.lookup('desc-set'))
      end
    end

    def do_fail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].fail = message
        Interface.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end
    
    def do_success(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].succ = message
        Interface.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end
    
    def do_osuccess(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].osucc = message
        Interface.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end
    
    def do_ofail(player, name, message)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].ofail = message
        Interface.do_notify(player, Phrasebook.lookup('message-set'))
      end
    end
    
    def do_lock(player, name, keyname) 
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()
  
      thing = @match.match_result()
      case thing
        when NOTHING
          Interface.do_notify(player, Phrasebook.lookup('dont-see-lock'))
          return
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('which-one-lock'))
          return
        else
          if (!@predicates.controls(player, thing))
              Interface.do_notify(player, Phrasebook.lookup('bad-lock'))
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
          Interface.do_notify(player, Phrasebook.lookup('no-key'))
          return
        when AMBIGUOUS
        Interface.do_notify(player, Phrasebook.lookup('which-key'))
        return
        else
          if (!is_player(key) && !is_thing(key))
              Interface.do_notify(player, Phrasebook.lookup('bad-key-link'))
              return
          end
      end
      
      # everything ok, do it
      @db[thing].key = key
      if (antilock)
        @db[thing].flags |= ANTILOCK
        Interface.do_notify(player, Phrasebook.lookup('anti-locked'))
      else
        @db[thing].flags &= ~ANTILOCK
        Interface.do_notify(player, Phrasebook.lookup('locked'))
      end
    end
  
    def do_unlock(player, name)
      thing = match_controlled(player, name)
      if (thing != NOTHING)
        @db[thing].key = NOTHING
        @db[thing].flags &= ~ANTILOCK
        Interface.do_notify(player, Phrasebook.lookup('unlocked'))
      end
    end
    
    def do_unlink(player, name)
      @match.init_match(player, name, TYPE_EXIT)
      @match.match_exit()
      @match.match_here()
      @match.match_absolute() if(is_wizard(player))
  
      exit = @match.match_result()
      case exit
        when NOTHING
          Interface.do_notify(player, Phrasebook.lookup('unlink-what'))
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('which-one'))
        else
          if (!@predicates.controls(player, exit))
              Interface.do_notify(player, Phrasebook.lookup('no-permission'))
          else
            case typeof(exit)
              when TYPE_EXIT
                @db[exit].location = NOTHING
                Interface.do_notify(player, Phrasebook.lookup('unlinked'))
              when TYPE_ROOM
                @db[exit].location = NOTHING
                Interface.do_notify(player, Phrasebook.lookup('drop-to-removed'))
              else
                Interface.do_notify(player, Phrasebook.lookup('cant-unlink-that'))
            end
          end
      end
    end

    def do_chown(player, name, newobj)
      if (!is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('no-permission'))
      else
        @match.init_match(player, name, NOTYPE)
        @match.match_everything()
        thing = @match.noisy_match_result()
        owner = @player.lookup_player(newobj)
        if (thing == NOTHING)
            return
        elsif (owner == NOTHING)
            Interface.do_notify(player, Phrasebook.lookup('no-player'))
        elsif (player?(thing))
            Interface.do_notify(player, Phrasebook.lookup('own-self'))
        else
            @db[thing].owner = owner
            Interface.do_notify(player, Phrasebook.lookup('owner-changed'))
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
        Interface.do_notify(player, Phrasebook.lookup('specify-a-flag'))
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
        Interface.do_notify(player, Phrasebook.lookup('unknown-flag'))
        return
      end

      # check for restricted flag
      if (!is_wizard(player) && (f == WIZARD || f == TEMPLE || (f == DARK && !room?(thing))))
        Interface.do_notify(player, Phrasebook.lookup('no-permission'))
        return
      end
  
      # check for stupid wizard
      if (f == WIZARD && flag[0] == NOT_TOKEN && thing == player)
        Interface.do_notify(player, Phrasebook.lookup('cant-be-mortal'))
        return
      end
  
      # else everything is ok, do the set
      if (flag[0] == NOT_TOKEN)
        # reset the flag
        @db[thing].flags &= ~f
        Interface.do_notify(player, Phrasebook.lookup('flag-reset'))
      else
        # set the flag
        @db[thing].flags |= f
        Interface.do_notify(player, Phrasebook.lookup('flag-set'))
      end
    end

    private

    def match_controlled(player, name)
      @match.init_match(player, name, NOTYPE)
      @match.match_everything()

      match = @match.noisy_match_result()
      if (match != NOTHING && !@predicates.controls(player, match))
        Interface.do_notify(player, Phrasebook.lookup('no-permission'))
        NOTHING
      else
        match
      end
    end

  end
end
