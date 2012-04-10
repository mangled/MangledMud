require_relative 'helpers'

module MangledMud

  # Handles wizard related actions (the player performing these actions must be a wizard (this is checked throughout))
  #
  # @version 1.0
  class Wiz
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier

      @match = Match.new(@db, notifier)
      @move = Move.new(@db, notifier)
      @player = Player.new(@db, notifier)
    end

    # Teleport self or another player to a location, calling back on the notifier passed into the initializer.
    #
    # @param [Number] player the database record number for the player executing the teleport
    # @param [String] arg1 either the name of the player to teleport, or if arg2 is empty the location to transport player
    # @param [String] arg2 the destination, if empty then arg1 represents the destination for player
    def do_teleport(player, arg1, arg2)
      if (!is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('bad-teleport'))
        return
      end

      # get victim, destination
      victim = nil
      to = nil
      if (arg2.nil? || arg2.empty?)
        victim = player
        to = arg1
      else
        @match.init_match(player, arg1, NOTYPE)
        @match.match_neighbor()
        @match.match_possession()
        @match.match_me()
        @match.match_absolute()
        @match.match_player()

        victim = @match.noisy_match_result()
        return if (victim == NOTHING)
        to = arg2
      end

      # get destination
      @match.init_match(player, to, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_me()
      @match.match_here()
      @match.match_absolute()
      @match.match_player()

      destination = @match.match_result()
      case destination
      when NOTHING
        @notifier.do_notify(player, Phrasebook.lookup('send-where'))
      when AMBIGUOUS
        @notifier.do_notify(player, Phrasebook.lookup('which-dest'))
      else
        # check victim, destination types, teleport if ok
        if (exit?(destination) ||
          thing?(destination) ||
          exit?(victim) ||
          room?(victim) ||
          (player?(victim) && !room?(destination)))
          @notifier.do_notify(player, Phrasebook.lookup('bad-destination'))
        elsif (player?(victim))
          @notifier.do_notify(victim, Phrasebook.lookup('feel-weird'))
          @move.enter_room(victim, destination)
        else
          @move.moveto(victim, destination)
        end
      end
    end

    # Force another player to perform a command, calling back on the notifier passed into the initializer.
    #
    # @param [Game] the current game instance
    # @param [Number] player the database record number for the player executing the action
    # @param [Number] what the database record number of the player being forced
    # @param [String] command the command that the forced player is to perform
    def do_force(game, player, what, command)
      if (!is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('only-wizard'))
        return
      end

      # get victim
      victim = @player.lookup_player(what)
      if (victim == NOTHING)
        @notifier.do_notify(player, Phrasebook.lookup('player-does-not-exist'))
        return
      end

      # force victim to do command
      if game
        game.process_command(victim, command)
      else
        # This is here for testing purposes only
        @notifier.do_process_command(victim, command)
      end
    end

    # Dump some statistics regarding the players world, calling back on the notifier passed into the initializer
    # (non wizards see very little).
    #
    # @param [Number] player the database record number for the player executing the action
    # @param [Number] name the database record number of the player being examined, if {NOTHING} then examine the whole game universe
    def do_stats(player, name)
      if (!is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('universe-contains', @db.length))
      else
        owner = @player.lookup_player(name)
        total = rooms = exits = things = players = unknowns = 0
        0.upto(@db.length - 1) do |i|
          if (owner == NOTHING || owner == @db[i].owner)
            total = total + 1
            case typeof(i)
            when TYPE_ROOM
              rooms = rooms + 1
            when TYPE_EXIT
              exits = exits + 1
            when TYPE_THING
              things = things + 1
            when TYPE_PLAYER
              players = players + 1
            else
              unknowns = unknowns + 1
            end
          end
        end
        @notifier.do_notify(player, Phrasebook.lookup('universe-details', total, rooms, exits, things, players, unknowns))
      end
    end

    # Change a player into a toad, calling back on the notifier passed into the initializer
    #
    # @param [Number] player the database record number for the player executing the action
    # @param [Number] name the database record number of the player being turned into a slimy thing :-)
    def do_toad(player, name)
      if (!is_wizard(player))
        @notifier.do_notify(player, Phrasebook.lookup('bad-toad'))
        return
      end

      @match.init_match(player, name, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_absolute()
      @match.match_player()
      victim = @match.noisy_match_result()

      return if (victim == NOTHING)

      if (!player?(victim))
        @notifier.do_notify(player, Phrasebook.lookup('can-only-toad-players'))
      elsif (is_wizard(victim))
        @notifier.do_notify(player, Phrasebook.lookup('cant-toad-wizard'))
      elsif (@db[victim].contents != NOTHING)
        @notifier.do_notify(player, Phrasebook.lookup('what-about-them'))
      else
        # we're ok
        # do it
        if (@db[victim].password)
          @db[victim].password = nil
        end
        @db[victim].flags = TYPE_THING
        @db[victim].owner = player # you get it
        @db[victim].pennies = 1 # don't let him keep his immense wealth

        # notify people
        @notifier.do_notify(victim, Phrasebook.lookup('you-become-a-toad'))
        @notifier.do_notify(player, Phrasebook.lookup('you-toaded', @db[victim].name))

        # reset name
        @db[victim].name = Phrasebook.lookup('toad-name', @db[victim].name)
      end
    end
  end
end
