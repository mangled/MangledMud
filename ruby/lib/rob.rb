require_relative '../test/include'
require_relative '../test/defines.rb'
require_relative './helpers.rb'

module TinyMud
  class Rob
    include Helpers

    def initialize(db)
      @db = db
      @match = Match.new(@db)
      @predicates = Predicates.new(@db)
      @move = Move.new(@db)
      @speech = Speech.new(@db)
    end

    def do_rob(player, what)
      loc = getloc(player)
      return if (loc == NOTHING)

      @match.init_match(player, what, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_me()
      if (is_wizard(player))
        @match.match_absolute()
        @match.match_player()
      end
      thing = @match.match_result()
    
      case thing
        when NOTHING
          Interface.do_notify(player, "Rob whom?")
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know who you mean!")
        else
          if (typeof(thing) != TYPE_PLAYER)
              Interface.do_notify(player, "Sorry, you can only rob other players.")
          elsif (@db[thing].pennies < 1)
              Interface.do_notify(player, "#{@db[thing].name} is penniless.")
              Interface.do_notify(thing, "#{@db[player].name} tried to rob you, but you have no pennies to take.")
          elsif(@predicates.can_doit(player, thing, "Your conscience tells you not to."))
              # steal a penny
              @db[player].pennies = @db[player].pennies + 1
              @db[thing].pennies = @db[thing].pennies - 1
              Interface.do_notify(player, "You stole a penny.")
              Interface.do_notify(thing, "#{@db[player].name} stole one of your pennies!")
          end
      end
    end

    def do_kill(player, what, cost)
      @match.init_match(player, what, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_me()
      if (is_wizard(player))
        @match.match_player()
        @match.match_absolute()
      end
      victim = @match.match_result()

      case victim
        when NOTHING
          Interface.do_notify(player, "I don't see that player here.")
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know who you mean!")
        else
          if (typeof(victim) != TYPE_PLAYER)
              Interface.do_notify(player, "Sorry, you can only kill other players.")
          elsif (is_wizard(victim))
              Interface.do_notify(player, "Sorry, Wizards are immortal.")
          else
            # go for it set cost 
            cost = KILL_MIN_COST if (cost < KILL_MIN_COST)
    
            # see if it works 
            if (!@predicates.payfor(player, cost))
              Interface.do_notify(player, "You don't have enough pennies.")
            elsif ((Game.do_rand() % KILL_BASE_COST) < cost)
              # you killed him
              Interface.do_notify(player, "You killed #{@db[victim].name}!")

              # notify victim 
              Interface.do_notify(victim, "#{@db[player].name} killed you!")
              Interface.do_notify(victim, "Your insurance policy pays #{KILL_BONUS} pennies.")

              # pay off the bonus 
              @db[victim].pennies = @db[victim].pennies + KILL_BONUS

              # send him home 
              @move.send_home(victim)

              # now notify everybody else 
              @speech.notify_except(@db[@db[player].location].contents, player, "#{@db[player].name} killed #{@db[victim].name}!")
            else
              # notify player and victim only 
              Interface.do_notify(player, "Your murder attempt failed.")
              Interface.do_notify(victim, "#{@db[player].name} tried to kill you!")
            end
          end
      end
    end

    def do_give(player, recipient, amount)
      # do amount consistency check 
      if (amount < 0 && !is_wizard(player))
        Interface.do_notify(player, "Try using the \"rob\" command.")
        return
      elsif (amount == 0)
        Interface.do_notify(player, "You must specify a positive number of pennies.")
        return
      end

      # check recipient 
      @match.init_match(player, recipient, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_me()
      if (is_wizard(player))
        @match.match_player()
        @match.match_absolute()
      end
      who = @match.match_result()

      case who
        when NOTHING
          Interface.do_notify(player, "Give to whom?")
          return
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know who you mean!")
          return
        else
          if (!is_wizard(player))
              if (typeof(who) != TYPE_PLAYER)
                Interface.do_notify(player, "You can only give to other players.")
                return
              elsif (@db[who].pennies + amount > MAX_PENNIES)
                Interface.do_notify(player, "That player doesn't need that many pennies!")
                return
              end
          end
      end

      # try to do the give 
      if (!@predicates.payfor(player, amount))
        Interface.do_notify(player, "You don't have that many pennies to give!")
      else
        # he can do it 
        Interface.do_notify(player, "You give #{amount} #{amount == 1 ? "penny" : "pennies"} to #{@db[who].name}.")
        if (typeof(who) == TYPE_PLAYER)
            Interface.do_notify(who, "#{@db[player].name} gives you #{amount} #{amount == 1 ? "penny" : "pennies"}.")
        end
        @db[who].pennies = @db[who].pennies + amount
      end
    end

  end
end
