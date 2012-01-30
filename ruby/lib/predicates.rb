require_relative '../test/include'
require_relative '../test/defines.rb'

module TinyMud
  class Predicates

    def initialize(db)
      @db = db
    end

    def can_link_to(who, where)
    end
    
    def could_doit(player, thing)
    end
    
    def can_doit(player, thing, default_fail_msg)
    end
    
    def can_see(player, thing, can_see_loc)
    end
    
    def controls(who, what)
    end
    
    def can_link(who, what)
    end
    
    def payfor(who, cost)
    end
    
    def ok_name(name)
    end
    
    def ok_player_name(name)
    end
  end
end
