require_relative 'helpers'

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
          Interface.do_notify(player, Phrasebook.lookup('rob-whom'))
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('who'))
        else
          if (!player?(thing))
              Interface.do_notify(player, Phrasebook.lookup('sorry-only-rob-players'))
          elsif (@db[thing].pennies < 1)
              Interface.do_notify(player, Phrasebook.lookup('penniless', @db[thing].name))
              Interface.do_notify(thing, Phrasebook.lookup('tried-to-rob-you', @db[player].name))
          elsif(@predicates.can_doit(player, thing, Phrasebook.lookup('you-have-a-conscience')))
              # steal a penny
              @db[player].pennies = @db[player].pennies + 1
              @db[thing].pennies = @db[thing].pennies - 1
              Interface.do_notify(player, Phrasebook.lookup('stole-penny'))
              Interface.do_notify(thing, Phrasebook.lookup('stole-from-you', @db[player].name))
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
          Interface.do_notify(player, Phrasebook.lookup('dont-see-player'))
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('who'))
        else
          if (!player?(victim))
              Interface.do_notify(player, Phrasebook.lookup('sorry-only-kill-players'))
          elsif (is_wizard(victim))
              Interface.do_notify(player, Phrasebook.lookup('sorry-wizard-immortal'))
          else
            # go for it set cost 
            cost = KILL_MIN_COST if (cost < KILL_MIN_COST)
    
            # see if it works 
            if (!@predicates.payfor(player, cost))
              Interface.do_notify(player, Phrasebook.lookup('too-poor'))
            elsif ((Game.do_rand() % KILL_BASE_COST) < cost)
              # you killed him
              Interface.do_notify(player, "You killed #{@db[victim].name}!")

              # notify victim 
              Interface.do_notify(victim, Phrasebook.lookup('killed-you', @db[player].name))
              Interface.do_notify(victim, Phrasebook.lookup('insurance-pays-out', KILL_BONUS))

              # pay off the bonus 
              @db[victim].pennies = @db[victim].pennies + KILL_BONUS

              # send him home 
              @move.send_home(victim)

              # now notify everybody else 
              @speech.notify_except(@db[@db[player].location].contents, player, Phrasebook.lookup('killed', @db[player].name, @db[victim].name))
            else
              # notify player and victim only 
              Interface.do_notify(player, Phrasebook.lookup('murder-failed'))
              Interface.do_notify(victim, Phrasebook.lookup('tried-to-kill-you', @db[player].name))
            end
          end
      end
    end

    def do_give(player, recipient, amount)
      # do amount consistency check 
      if (amount < 0 && !is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('try-rob-command'))
        return
      elsif (amount == 0)
        Interface.do_notify(player, Phrasebook.lookup('specify-positive-pennies'))
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
          Interface.do_notify(player, Phrasebook.lookup('give-to-whom'))
          return
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('who'))
          return
        else
          if (!is_wizard(player))
              if (!player?(who))
                Interface.do_notify(player, Phrasebook.lookup('can-only-give-to-others'))
                return
              elsif (@db[who].pennies + amount > MAX_PENNIES)
                Interface.do_notify(player, Phrasebook.lookup('player-too-rich'))
                return
              end
          end
      end

      # try to do the give 
      if (!@predicates.payfor(player, amount))
        Interface.do_notify(player, Phrasebook.lookup('not-rich-enough'))
      else
        # he can do it
        if amount == 1
          Interface.do_notify(player, Phrasebook.lookup('you-give-a-penny', @db[who].name))
          if (player?(who))
              Interface.do_notify(who, Phrasebook.lookup('gives-you-a-penny', @db[player].name))
          end
        else
          Interface.do_notify(player, Phrasebook.lookup('you-give-pennies', amount, @db[who].name))
          if (player?(who))
              Interface.do_notify(who, Phrasebook.lookup('gives-you-pennies', @db[player].name, amount))
          end
        end
        @db[who].pennies = @db[who].pennies + amount
      end
    end

  end
end
