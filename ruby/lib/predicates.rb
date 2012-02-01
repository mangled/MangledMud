require_relative '../test/include'
require_relative '../test/defines.rb'
require_relative './helpers.rb'

module TinyMud
  class Predicates
    include Helpers

    def initialize(db)
      @db = db
    end

    def can_link_to(who, where)
      c_truthify(
        where >= 0 &&
        where < @db.length &&
        typeof(where) == TYPE_ROOM &&
        (r_truthify(controls(who, where)) || r_truthify(@db.get(where).flags & LINK_OK))
      )
    end

    def could_doit(player, thing)
      return 0 if (typeof(thing) != TYPE_ROOM && @db.get(thing).location == NOTHING)
      return 1 if ((key = @db.get(thing).key) == NOTHING)
      status = (player == key || r_truthify(Utils.new(@db).member(key, @db.get(player).contents)))
      return c_truthify(r_truthify(@db.get(thing).flags & ANTILOCK) ? !status : status)
    end
  
    def can_doit(player, thing, default_fail_msg)
      loc = getloc(player)

      return 0 if (loc == NOTHING)

      if (!r_truthify(could_doit(player, thing)))
        # can't do it
        if (@db.get(thing).fail)
          Interface.do_notify(player, @db.get(thing).fail)
        elsif (default_fail_msg)
          Interface.do_notify(player, default_fail_msg)
        end
  
        if (@db.get(thing).ofail)
          Speech.new(@db).notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} #{@db.get(thing).ofail}".to_s)
        end
        0
      else
        # can do it
        if (@db.get(thing).succ)
          Interface.do_notify(player, @db.get(thing).succ)
        end
    
        if (@db.get(thing).osucc)
          Speech.new(@db).notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} #{@db.get(thing).osucc}")
        end
        1
      end
    end
  
    def can_see(player, thing, can_see_loc)
      if (player == thing || typeof(thing) == TYPE_EXIT)
        return 0
      elsif can_see_loc
        return c_truthify(!is_dark(thing) || r_truthify(controls(player, thing)))
      else
        # can't see loc
        controls(player, thing)
      end
    end
    
    def controls(who, what)
      # Wizard controls everything
      # owners control their stuff
      c_truthify(
        what >= 0 &&
        what < @db.length &&
        (is_wizard(who) || who == @db.get(what).owner)
      )
    end
    
    def can_link(who, what)
      c_truthify(
        (typeof(what) == TYPE_EXIT && @db.get(what).location == NOTHING) ||
        r_truthify(controls(who, what))
      )
    end
    
    def payfor(who, cost)
      if (is_wizard(who))
        return 1
      elsif (@db.get(who).pennies >= cost)
        @db.get(who).pennies -= cost
        return 1
      else
        return 0
      end
    end

    def ok_name(name)
      c_truthify(
        !name.nil? &&
        !name.empty? &&
        (name[0] != 0.chr) &&
        (name[0] != LOOKUP_TOKEN) &&
        (name[0] != NUMBER_TOKEN) &&
        (name != "me") &&
        (name != "home") &&
        (name != "here")
      )
    end

    def ok_player_name(name)
      return 0 if name.nil?
      return 0 if (ok_name(name) == 0)
      return 0 if name.match(/[^[:graph:]]/)
      return c_truthify(Player.new(@db).lookup_player(name) == NOTHING)
    end
  end
end
