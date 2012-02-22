require_relative 'helpers'

module TinyMud
  class Wiz
    include Helpers

    def initialize(db)
      @db = db
      @match = Match.new(@db)
      @move = Move.new(@db)
      @player = Player.new(@db)
    end

    def do_teleport(player, arg1, arg2) 
      if (!is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('bad-teleport'))
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
          Interface.do_notify(player, Phrasebook.lookup('send-where'))
        when AMBIGUOUS
          Interface.do_notify(player, Phrasebook.lookup('which-dest'))
        else
          # check victim, destination types, teleport if ok 
          if (exit?(destination) ||
              thing?(destination) ||
              exit?(victim) ||
              room?(victim) ||
              (player?(victim) && !room?(destination)))
              Interface.do_notify(player, Phrasebook.lookup('bad-destination'))
          elsif(player?(victim))
              Interface.do_notify(victim, Phrasebook.lookup('feel-weird'))
              @move.enter_room(victim, destination)
          else
              @move.moveto(victim, destination)
          end
      end
    end

    def do_force(game, player, what, command)
      if (!is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('only-wizard'))
        return
      end
  
      # get victim
      victim = @player.lookup_player(what)
      if (victim == NOTHING)
        Interface.do_notify(player, Phrasebook.lookup('player-does-not-exist'))
        return
      end
  
      # force victim to do command
      if game
        game.process_command(victim, command)
      else
        Interface.do_process_command(victim, command)
      end
    end

    def do_stats(player, name) 
      if (!is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('universe-contains', @db.length))
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
        Interface.do_notify(player, Phrasebook.lookup('universe-details', total, rooms, exits, things, players, unknowns))
      end
    end

    def do_toad(player, name) 
      if (!is_wizard(player))
        Interface.do_notify(player, Phrasebook.lookup('bad-toad'))
        return
      end
  
      @match.init_match(player, name, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_absolute()
      @match.match_player()
      victim = @match.noisy_match_result()

      return if (victim == NOTHING)

      if (!player?(victim))
        Interface.do_notify(player, Phrasebook.lookup('can-only-toad-players'))
      elsif (is_wizard(victim))
        Interface.do_notify(player, Phrasebook.lookup('cant-toad-wizard'))
      elsif (@db[victim].contents != NOTHING)
        Interface.do_notify(player, Phrasebook.lookup('what-about-them'))
      else
        # we're ok 
        # do it 
        if (@db[victim].password)
            @db[victim].password = nil
        end
        @db[victim].flags = TYPE_THING
        @db[victim].owner = player # you get it 
        @db[victim].pennies = 1	# don't let him keep his immense wealth 

        # notify people 
        Interface.do_notify(victim, Phrasebook.lookup('you-become-a-toad'))
        Interface.do_notify(player, Phrasebook.lookup('you-toaded', @db[victim].name))
    
        # reset name 
        @db[victim].name = Phrasebook.lookup('toad-name', @db[victim].name)
      end
    end
  end
end
