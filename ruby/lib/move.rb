require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Move
    include Helpers

    def initialize(db)
      @db = db
      @utils = Utils.new(@db)
      @speech = Speech.new(@db)
      @predicates = Predicates.new(@db)
      @match = Match.new(@db)
    end

    def moveto(what, where)
      loc = @db.get(what).location
  
      # remove what from old loc
      if (loc != NOTHING)
        @db.get(loc).contents = @utils.remove_first(@db.get(loc).contents, what)
      end
  
      # test for special cases
      case where
        when NOTHING
          @db.get(what).location = NOTHING
          return # NOTHING doesn't have contents
        when HOME
          where = @db.get(what).exits # home
      end
  
      # now put what in where
      @db.get(what).next = @db.get(where).contents
      @db.get(where).contents = what
      @db.get(what).location = where
    end
    
    def enter_room(player, loc)
      # check for room == HOME
      loc = @db.get(player).exits if (loc == HOME) # home
  
      # get old location
      old = @db.get(player).location
  
      # check for self-loop
      # self-loops don't do move or other player notification
      # but you still get autolook and penny check
      if (loc != old)
          if (old != NOTHING)
              # notify others unless DARK
              if (!is_dark(old) && !is_dark(player))
                  @speech.notify_except(@db.get(old).contents, player, "#{@db.get(player).name} has left.")
              end
          end

          # go there
          moveto(player, loc)
      
          # if old location has STICKY dropto, send stuff through it
          if (old != NOTHING && (dropto = @db.get(old).location) != NOTHING && (is_sticky(old)))
              maybe_dropto(old, dropto)
          end
      
          # tell other folks in new location if not DARK
          if (!is_dark(loc) && !is_dark(player))
              @speech.notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} has arrived.")
          end
      end
  
      # autolook
      Look.new(@db).look_room(player, loc)
  
      # check for pennies
  
      # Added to allow mocking/control over when someone gets a penny
      give_penny = r_truthify(Move.get_penny_check())

      if (!r_truthify(@predicates.controls(player, loc)) && (@db.get(player).pennies <= MAX_PENNIES) && give_penny)
          Interface.do_notify(player, "You found a penny!")
          @db.get(player).pennies = @db.get(player).pennies + 1
      end
    end
    
    def send_home(thing)
      case typeof(thing)
        when TYPE_PLAYER
          # send his possessions home first!
          # that way he sees them when he arrives
          send_contents(thing, HOME)
          enter_room(thing, @db.get(thing).exits) # home
        when TYPE_THING
          moveto(thing, @db.get(thing).exits)	# home
        else
          # no effect
      end
    end
    
    def can_move(player, direction)
      return 1 if (direction.casecmp("home") == 0)
  
      # otherwise match on exits
      @match.init_match(player, direction, TYPE_EXIT)
      @match.match_exit()

      return c_truthify(@match.last_match_result() != NOTHING)
    end

    def do_move(player, direction)
      if (direction.casecmp("home") == 0)
        # send him home
        # but steal all his possessions
        loc = @db.get(player).location
        if (loc != NOTHING)
            # tell everybody else
            @speech.notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} goes home.")
        end
        # give the player the messages
        Interface.do_notify(player, "There's no place like home...")
        Interface.do_notify(player, "There's no place like home...")
        Interface.do_notify(player, "There's no place like home...")
        Interface.do_notify(player, "You wake up back home, without your possessions.")
        send_home(player)
      else
        # find the exit
        @match.init_match_check_keys(player, direction, TYPE_EXIT)
        @match.match_exit()
        exit = @match.match_result()
        case exit
          when NOTHING
            Interface.do_notify(player, "You can't go that way.")
          when AMBIGUOUS
            Interface.do_notify(player, "I don't know which way you mean!")
          else
            # we got one
            # check to see if we got through
            if (r_truthify(@predicates.can_doit(player, exit, "You can't go that way.")))
              enter_room(player, @db.get(exit).location)
            end
        end
      end
    end
    
    def do_get(player, what) 
      @match.init_match_check_keys(player, what, TYPE_THING)
      @match.match_neighbor()
      @match.match_exit()
      @match.match_absolute() if (is_wizard(player)) # the wizard has long fingers
  
      thing = @match.noisy_match_result()
      if (thing != NOTHING)
        if (@db.get(thing).location == player)
            Interface.do_notify(player, "You already have that!")
            return
        end
        case typeof(thing)
          when TYPE_THING
            if (r_truthify(@predicates.can_doit(player, thing, "You can't pick that up.")))
                moveto(thing, player)
                Interface.do_notify(player, "Taken.")
            end
          when TYPE_EXIT
            if (!r_truthify(@predicates.controls(player, thing)))
                Interface.do_notify(player, "You can't pick that up.")
            elsif (@db.get(thing).location != NOTHING)
                Interface.do_notify(player, "You can't pick up a linked exit.")
            else
                # take it out of location
                loc = getloc(player)
                return if (loc == NOTHING)
                if (!r_truthify(@utils.member(thing, @db.get(loc).exits)))
                    Interface.do_notify(player, "You can't pick up an exit from another room.")
                    return
                end
                @db.get(loc).exits = @utils.remove_first(@db.get(loc).exits, thing)
                @db.get(thing).next = @db.get(player).contents
                @db.get(player).contents = thing
                @db.get(thing).location = player
                Interface.do_notify(player, "Exit taken.")
            end
          else
            Interface.do_notify(player, "You can't take that!")
        end
      end
    end
    
    def do_drop(player, name)
      loc = getloc(player)
      return if (loc == NOTHING)
  
      @match.init_match(player, name, TYPE_THING)
      @match.match_possession()
      thing = @match.match_result()

      case thing
        when NOTHING
          Interface.do_notify(player, "You don't have that!")
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know which you mean!")
        else
          if (@db.get(thing).location != player)
              # Shouldn't ever happen. 
              Interface.do_notify(player, "You can't drop that.")
          elsif (typeof(thing) == TYPE_EXIT)
              # special behavior for exits 
              if (!r_truthify(@predicates.controls(player, loc)))
                Interface.do_notify(player, "You can't put an exit down here.")
                return
              end
              # else we can put it down 
              moveto(thing, NOTHING) # take it out of the pack 

              @db.get(thing).next = @db.get(loc).exits
              @db.get(loc).exits = thing
              Interface.do_notify(player, "Exit dropped.")
          elsif (is_temple(loc))
              # sacrifice time 
              send_home(thing)

              Interface.do_notify(player, "#{@db.get(thing).name} is consumed in a burst of flame!")
              @speech.notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} sacrifices #{@db.get(thing).name}.")
      
              # check for reward 
              if (!r_truthify(@predicates.controls(player, thing)))
                  reward = @db.get(thing).pennies
                  if (reward < 1 || @db.get(player).pennies > MAX_PENNIES)
                      reward = 1
                  elsif (reward > MAX_OBJECT_ENDOWMENT)
                      reward = MAX_OBJECT_ENDOWMENT
                  end
          
                  @db.get(player).pennies = @db.get(player).pennies + reward
                  Interface.do_notify(player, "You have received #{reward} #{reward == 1 ? "penny" : "pennies"} for your sacrifice.")
              end
          elsif (is_sticky(thing))
              send_home(thing)
              Interface.do_notify(player, "Dropped.")
          elsif (@db.get(loc).location != NOTHING && !is_sticky(loc))
              # location has immediate dropto 
              moveto(thing, @db.get(loc).location)
              Interface.do_notify(player, "Dropped.")
          else
              moveto(thing, loc)
              Interface.do_notify(player, "Dropped.")
              @speech.notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} dropped #{@db.get(thing).name}.")
          end
      end
    end
    
    # To allow mocking in move.c - enter_room()
    def Move.get_penny_check()
      (rand(0x7FFFFFFF) % PENNY_RATE == 0 ? 1 : 0)
    end

    private

    def send_contents(loc, dest)
        first = @db.get(loc).contents
        @db.get(loc).contents = NOTHING
    
        # blast locations of everything in list
        enum(first).each {|item| @db.get(item).location = NOTHING }
    
        while (first != NOTHING)
          rest = @db.get(first).next
          if (typeof(first) != TYPE_THING)
              moveto(first, loc)
          else
              moveto(first, is_sticky(first) ? HOME : dest)
          end
          first = rest
        end
        @db.get(loc).contents = @utils.reverse(@db.get(loc).contents)
    end

    def maybe_dropto(loc, dropto)
        return if (loc == dropto) # bizarre special case
    
        # check for players
        enum(@db.get(loc).contents).each do |i|
          return if is_player(i)
        end
        
        # no players, send everything to the dropto
        send_contents(loc, dropto)
    end

  end
end
