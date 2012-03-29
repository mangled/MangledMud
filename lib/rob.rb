require_relative 'helpers'

module MangledMud
  
  # Handles exchanging money and killing
  #
  # @version 1.0
  class Rob
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
      @match = Match.new(@db, notifier)
      @predicates = Predicates.new(@db, notifier)
      @move = Move.new(@db, notifier)
      @speech = Speech.new(@db, notifier)
    end

    # Attempt to rob someone, calling back on the notifier passed into the initializer
    #
    # @param [Number] player the database record identifier for the player attempting to rob
    # @param [Number] what the database record identifier for the thing being robbed (only players can be robbed, this is checked)
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
        @notifier.do_notify(player, Phrasebook.lookup('rob-whom'))
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('who'))
      else
        if (!player?(thing))
          @notifier.do_notify(player, Phrasebook.lookup('sorry-only-rob-players'))
        elsif (@db[thing].pennies < 1)
          @notifier.do_notify(player, Phrasebook.lookup('penniless', @db[thing].name))
          @notifier.do_notify(thing, Phrasebook.lookup('tried-to-rob-you', @db[player].name))
        elsif(@predicates.can_doit(player, thing, Phrasebook.lookup('you-have-a-conscience')))
          # steal a penny
          @db[player].pennies = @db[player].pennies + 1
          @db[thing].pennies = @db[thing].pennies - 1
          @notifier.do_notify(player, Phrasebook.lookup('stole-penny'))
          @notifier.do_notify(thing, Phrasebook.lookup('stole-from-you', @db[player].name))
        end
      end
    end

    # Attempt to kill another player, calling back on the notifier passed into the initializer
    #
    # @param [Number] player the database record identifier for the player attempting to kill
    # @param [Number] what the database record identifier for the thing being killed (only players can be killed, this is checked)
    # @param [Number] cost the amount being payed to perform the kill, the player must have at least {KILL_MIN_COST} pennies
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
        @notifier.do_notify(player, Phrasebook.lookup('dont-see-player'))
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('who'))
      else
        if (!player?(victim))
          @notifier.do_notify(player, Phrasebook.lookup('sorry-only-kill-players'))
        elsif (is_wizard(victim))
          @notifier.do_notify(player, Phrasebook.lookup('sorry-wizard-immortal'))
        else
          # go for it set cost
          cost = KILL_MIN_COST if (cost < KILL_MIN_COST)

          # see if it works
          if (!@predicates.payfor(player, cost))
            @notifier.do_notify(player, Phrasebook.lookup('too-poor'))
          elsif ((Game.do_rand() % KILL_BASE_COST) < cost)
            # you killed him
            @notifier.do_notify(player, "You killed #{@db[victim].name}!")

            # notify victim
            @notifier.do_notify(victim, Phrasebook.lookup('killed-you', @db[player].name))
            @notifier.do_notify(victim, Phrasebook.lookup('insurance-pays-out', KILL_BONUS))

            # pay off the bonus
            @db[victim].pennies = @db[victim].pennies + KILL_BONUS

            # send him home
            @move.send_home(victim)

            # now notify everybody else
            @speech.notify_except(@db[@db[player].location].contents, player, Phrasebook.lookup('killed', @db[player].name, @db[victim].name))
          else
            # notify player and victim only
            @notifier.do_notify(player, Phrasebook.lookup('murder-failed'))
            @notifier.do_notify(victim, Phrasebook.lookup('tried-to-kill-you', @db[player].name))
          end
        end
      end
    end

    # Give some money to a player - Only wizards can perform this, call back on the notifier passed into the initializer
    #
    # @param [Number] player the database record identifier for the player attempting to give
    # @param [Number] recipient the database record identifier for the recipient
    # @param [Number] amount the amount being given
    def do_give(player, recipient, amount)
      # do amount consistency check
      if (amount < 0 && !is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('try-rob-command'))
        return
      elsif (amount == 0)
        @notifier.do_notify(player, Phrasebook.lookup('specify-positive-pennies'))
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
        @notifier.do_notify(player, Phrasebook.lookup('give-to-whom'))
        return
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('who'))
        return
      else
        if (!is_wizard(player))
          if (!player?(who))
            @notifier.do_notify(player, Phrasebook.lookup('can-only-give-to-others'))
            return
          elsif (@db[who].pennies + amount > MAX_PENNIES)
            @notifier.do_notify(player, Phrasebook.lookup('player-too-rich'))
            return
          end
        end
      end

      # try to do the give
      if (!@predicates.payfor(player, amount))
        @notifier.do_notify(player, Phrasebook.lookup('not-rich-enough'))
      else
        # he can do it
        if amount == 1
          @notifier.do_notify(player, Phrasebook.lookup('you-give-a-penny', @db[who].name))
          if (player?(who))
            @notifier.do_notify(who, Phrasebook.lookup('gives-you-a-penny', @db[player].name))
          end
        else
          @notifier.do_notify(player, Phrasebook.lookup('you-give-pennies', amount, @db[who].name))
          if (player?(who))
            @notifier.do_notify(who, Phrasebook.lookup('gives-you-pennies', @db[player].name, amount))
          end
        end
        @db[who].pennies = @db[who].pennies + amount
      end
    end

  end
end
