require_relative '../test/include'
require_relative '../test/defines.rb'
require_relative './helpers.rb'

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
        Interface.do_notify(player, "Only a Wizard may teleport at will.")
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
          Interface.do_notify(player, "Send it where?")
        when AMBIGUOUS
          Interface.do_notify(player, "I don't know which destination you mean!")
        else
          # check victim, destination types, teleport if ok 
          if (typeof(destination) == TYPE_EXIT ||
              typeof(destination) == TYPE_THING ||
              typeof(victim) == TYPE_EXIT ||
              typeof(victim) == TYPE_ROOM ||
              (typeof(victim) == TYPE_PLAYER && typeof(destination) != TYPE_ROOM))
              Interface.do_notify(player, "Bad destination.")
          elsif(typeof(victim) == TYPE_PLAYER)
              Interface.do_notify(victim, "You feel a wrenching sensation...")
              @move.enter_room(victim, destination)
          else
              @move.moveto(victim, destination)
          end
      end
    end
    
    def do_force(player, what, command) 
      if (!is_wizard(player))
        Interface.do_notify(player, "Only Wizards may use this command.")
        return
      end
  
      # get victim
      victim = @player.lookup_player(what)
      if (victim == NOTHING)
        Interface.do_notify(player, "That player does not exist.")
        return
      end
  
      # force victim to do command
      # NOTE: This needs to/will change, it should go to Game.process_command()
      Interface.do_process_command(victim, command)
    end

    def do_stats(player, name) 
      if (!is_wizard(player))
        Interface.do_notify(player, "The universe contains #{@db.length} objects.")
      else
        owner = @player.lookup_player(name)
        total = rooms = exits = things = players = unknowns = 0
        0.upto(@db.length - 1) do |i|
          if (owner == NOTHING || owner == @db.get(i).owner)
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
        Interface.do_notify(player, "#{total} objects = #{rooms} rooms, #{exits} exits, #{things} things, #{players} players, #{unknowns} unknowns.")
      end
    end

    def do_toad(player, name) 
      if (!is_wizard(player))
        Interface.do_notify(player, "Only a Wizard can turn a person into a toad.")
        return
      end
  
      @match.init_match(player, name, TYPE_PLAYER)
      @match.match_neighbor()
      @match.match_absolute()
      @match.match_player()
      victim = @match.noisy_match_result()

      return if (victim == NOTHING)

      if (typeof(victim) != TYPE_PLAYER)
        Interface.do_notify(player, "You can only turn players into toads!")
      elsif (is_wizard(victim))
        Interface.do_notify(player, "You can't turn a Wizard into a toad.")
      elsif (@db.get(victim).contents != NOTHING)
        Interface.do_notify(player, "What about what they are carrying?")
      else
        # we're ok 
        # do it 
        if (@db.get(victim).password)
            @db.get(victim).password = nil
        end
        @db.get(victim).flags = TYPE_THING
        @db.get(victim).owner = player # you get it 
        @db.get(victim).pennies = 1	# don't let him keep his immense wealth 

        # notify people 
        Interface.do_notify(victim, "You have been turned into a toad.")
        Interface.do_notify(player, "You turned #{@db.get(victim).name} into a toad!")
    
        # reset name 
        @db.get(victim).name = "a slimy toad named #{@db.get(victim).name}"
      end
    end
  end
end
