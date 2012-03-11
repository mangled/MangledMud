require_relative 'helpers'

module TinyMud
  class Predicates
    include Helpers

    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    def can_link_to(who, where)
        where >= 0 &&
        where < @db.length &&
        room?(where) &&
        (controls(who, where) || is_link_ok(where))
    end

    def could_doit(player, thing)
      return false if (!room?(thing) && @db[thing].location == NOTHING)
      return true if ((key = @db[thing].key) == NOTHING)
      status = (player == key || Utils.new(@db).member(key, @db[player].contents))
      return is_antilock(thing) ? !status : status
    end
  
    def can_doit(player, thing, default_fail_msg)
      loc = getloc(player)

      return false if (loc == NOTHING)

      if (!could_doit(player, thing))
        # can't do it
        if (@db[thing].fail)
          @notifier.do_notify(player, @db[thing].fail)
        elsif (default_fail_msg)
          @notifier.do_notify(player, default_fail_msg)
        end
  
        if (@db[thing].ofail)
          Speech.new(@db, @notifier).notify_except(@db[loc].contents, player, "#{@db[player].name} #{@db[thing].ofail}".to_s)
        end
        false
      else
        # can do it
        if (@db[thing].succ)
          @notifier.do_notify(player, @db[thing].succ)
        end
    
        if (@db[thing].osucc)
          Speech.new(@db, @notifier).notify_except(@db[loc].contents, player, "#{@db[player].name} #{@db[thing].osucc}")
        end
        true
      end
    end
  
    def can_see(player, thing, can_see_loc)
      if (player == thing || exit?(thing))
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
      (is_wizard(who) || who == @db[what].owner)
    end
    
    def can_link(who, what)
      (exit?(what) && @db[what].location == NOTHING) || controls(who, what)
    end
    
    def payfor(who, cost)
      if (is_wizard(who))
        return true
      elsif (@db[who].pennies >= cost)
        @db[who].pennies -= cost
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
      return Player.new(@db, @notifier).lookup_player(name) == NOTHING
    end
  end
end
