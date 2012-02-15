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
        where >= 0 &&
        where < @db.length &&
        typeof(where) == TYPE_ROOM &&
        (controls(who, where) || is_link_ok(where))
    end

    def could_doit(player, thing)
      return false if (typeof(thing) != TYPE_ROOM && @db.get(thing).location == NOTHING)
      return true if ((key = @db.get(thing).key) == NOTHING)
      status = (player == key || Utils.new(@db).member(key, @db.get(player).contents))
      return is_antilock(thing) ? !status : status
    end
  
    def can_doit(player, thing, default_fail_msg)
      loc = getloc(player)

      return false if (loc == NOTHING)

      if (!could_doit(player, thing))
        # can't do it
        if (@db.get(thing).fail)
          Interface.do_notify(player, @db.get(thing).fail)
        elsif (default_fail_msg)
          Interface.do_notify(player, default_fail_msg)
        end
  
        if (@db.get(thing).ofail)
          Speech.new(@db).notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} #{@db.get(thing).ofail}".to_s)
        end
        false
      else
        # can do it
        if (@db.get(thing).succ)
          Interface.do_notify(player, @db.get(thing).succ)
        end
    
        if (@db.get(thing).osucc)
          Speech.new(@db).notify_except(@db.get(loc).contents, player, "#{@db.get(player).name} #{@db.get(thing).osucc}")
        end
        true
      end
    end
  
    def can_see(player, thing, can_see_loc)
      if (player == thing || typeof(thing) == TYPE_EXIT)
        return false
      elsif can_see_loc
        return !is_dark(thing) || controls(player, thing)
      else
        # can't see loc
        controls(player, thing)
      end
    end
    
    def controls(who, what)
      # Wizard controls everything
      # owners control their stuff
      what >= 0 &&
      what < @db.length &&
      (is_wizard(who) || who == @db.get(what).owner)
    end
    
    def can_link(who, what)
      (typeof(what) == TYPE_EXIT && @db.get(what).location == NOTHING) || controls(who, what)
    end
    
    def payfor(who, cost)
      if (is_wizard(who))
        return true
      elsif (@db.get(who).pennies >= cost)
        @db.get(who).pennies -= cost
        return true
      else
        return false
      end
    end

    def ok_name(name)
      !name.nil? &&
      !name.empty? &&
      (name[0] != 0.chr) &&
      (name[0] != LOOKUP_TOKEN) &&
      (name[0] != NUMBER_TOKEN) &&
      (name != "me") &&
      (name != "home") &&
      (name != "here")
    end

    def ok_player_name(name)
      return false if name.nil?
      return false unless ok_name(name)
      return false if name.match(/[^[:graph:]]/)
      return Player.new(@db).lookup_player(name) == NOTHING
    end
  end
end
