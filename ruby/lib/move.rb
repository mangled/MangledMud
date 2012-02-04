require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Move
    include Helpers

    def initialize(db)
      @db = db
    end

    def moveto(what, where)
    end
    
    def enter_room(player, loc)
    end
    
    def send_home(thing)
    end
    
    def can_move(player, direction)
    end
    
    def do_move(player, direction)
    end
    
    def do_get(player, what)
    end
    
    def do_drop(player, name)
    end
    
    # To allow mocking in move.c - enter_room()
    def Move.get_penny_check()
    end

  end
end
