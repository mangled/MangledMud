require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Look
    include Helpers

    def initialize(db)
      @db = db
      @predicates = Predicates.new(@db)
      @utils = Utils.new(@db)
      @match = Match.new(@db)
    end

    def look_room(player, loc)   
        # tell him the name, and the number if he can link to it 
        if (r_truthify(@predicates.can_link_to(player, loc)))
            Interface.do_notify(player, "#{@utils.getname(loc)} (##{loc})")
        else
            Interface.do_notify(player, @utils.getname(loc))
        end

        # tell him the description 
        Interface.do_notify(player, @db.get(loc).description) if (@db.get(loc).description)
    
        # tell him the appropriate messages if he has the key 
        @predicates.can_doit(player, loc, 0)
    
        # tell him the contents 
        look_contents(player, loc, "Contents:")
    end
    
    def do_look_around(player)
      loc = getloc(player)
      return if (loc == NOTHING)
      look_room(player, loc)
    end

    def do_look_at(player, name) 
      if (name.nil? || name.empty?)
        thing = getloc(player)
        if (thing != NOTHING)
            look_room(player, thing)
        end
      else
        # look at a thing here 
        @match.init_match(player, name, NOTYPE)
        @match.match_exit()
        @match.match_neighbor()
        @match.match_possession()
        if (is_wizard(player))
            @match.match_absolute()
            @match.match_player()
        end
        @match.match_here()
        @match.match_me()
        thing = @match.noisy_match_result()

        if (thing != NOTHING)
          case typeof(thing)
            when TYPE_ROOM
              look_room(player, thing)
            when TYPE_PLAYER
              look_simple(player, thing)
              look_contents(player, thing, "Carrying:")
            else
              look_simple(player, thing)
          end
        end
      end
    end
    
    def do_examine(player, name)
      thing = getloc(player)
      if (!name.nil? && !name.empty?)
          # look it up 
          @match.init_match(player, name, NOTYPE)
          @match.match_exit()
          @match.match_neighbor()
          @match.match_possession()
          @match.match_absolute()
          # only Wizards can examine other players 
          @match.match_player() if (is_wizard(player))
          @match.match_here()
          @match.match_me()
          thing = @match.noisy_match_result()
      end
      return if (thing == NOTHING)

      if (!r_truthify(@predicates.can_link(player, thing)))
        Interface.do_notify(player, "You can only examine what you own.  Try using \"look.\"")
        return
      end
  
      r = @db.get(thing)
      Interface.do_notify(
        player,
        "#{@utils.getname(thing)}(##{thing}) [#{@utils.getname(r.owner)}] " +
        "Key: #{(r.flags & ANTILOCK) != 0 ? NOT_TOKEN : ' '}" +
        "#{@utils.getname(r.key)}(##{r.key}) Pennies: " +
        "#{r.pennies} #{flag_description(thing)}"
      )

      Interface.do_notify(player, r.description) if (r.description)

      if (r.fail)
        Interface.do_notify(player, "Fail: #{r.fail}")
      end
      if (r.succ)
        Interface.do_notify(player, "Success: #{r.succ}")
      end
      if (r.ofail)
        Interface.do_notify(player, "Ofail: #{r.ofail}")
      end
      if (r.osucc)
        Interface.do_notify(player, "Osuccess: #{r.osucc}")
      end
  
      # show him the contents 
      if (r.contents != NOTHING)
        Interface.do_notify(player, "Contents:")
        enum(r.contents).each do |item|
          notify_name(player, item)
        end
      end
  
      case typeof(thing)
          when TYPE_ROOM
            # tell him about exits 
            if (r.exits != NOTHING)
                Interface.do_notify(player, "Exits:")
                enum(r.exits).each {|exit| notify_name(player, exit) }
            else
                Interface.do_notify(player, "No exits.")
            end
        
            # print dropto if present 
            if (r.location != NOTHING)
                Interface.do_notify(player, "Dropped objects go to: #{@utils.getname(r.location)}(##{r.location})")
            end
          when TYPE_THING # Fixme - This is a repeat of the TYPE_PLAYER check, no ruby case drop-through!!!!
            # print home 
            Interface.do_notify(player, "Home: #{@utils.getname(r.exits)}(##{r.exits})")
            
            # print location if player can link to it 
            if (r.location != NOTHING &&
               (r_truthify(@predicates.controls(player, r.location)) ||
                r_truthify(@predicates.can_link_to(player, r.location)))
            )
                Interface.do_notify(player, "Location: #{@utils.getname(r.location)}(##{r.location})")
            end
          when TYPE_PLAYER
            # print home 
            Interface.do_notify(player, "Home: #{@utils.getname(r.exits)}(##{r.exits})")

            # print location if player can link to it 
            if (r.location != NOTHING &&
               (r_truthify(@predicates.controls(player, r.location)) ||
                r_truthify(@predicates.can_link_to(player, r.location)))
            )
                Interface.do_notify(player, "Location: #{@utils.getname(r.location)}(##{r.location})")
            end
          when TYPE_EXIT
            # print destination 
            case r.location
              when NOTHING
              when HOME
                Interface.do_notify(player, "Destination: ***HOME***")
              else
                Interface.do_notify(player, "#{typeof(r.location) == TYPE_ROOM ? "Destination" : "Carried by"}: #{@utils.getname(r.location)}(##{r.location})")
            end
      end
    end

    def do_score(player)
      Interface.do_notify(player, "You have #{@db.get(player).pennies} #{@db.get(player).pennies == 1 ? "penny" : "pennies"}.")
    end
    
    def do_inventory(player)
      thing = @db.get(player).contents
      if (thing == NOTHING)
        Interface.do_notify(player, "You aren't carrying anything.")
      else
        Interface.do_notify(player, "You are carrying:")
        enum(thing).each do |item|
           notify_name(player, item)
        end
      end
      do_score(player)
    end
    
    def do_find(player, name)
      if (!r_truthify(@predicates.payfor(player, LOOKUP_COST)))
        Interface.do_notify(player, "You don't have enough pennies.")
      else
        0.upto(@db.length - 1) do |i|
            # Note: this isn't the same code as the original stringutil, fix
            if (typeof(i) != TYPE_EXIT && r_truthify(@predicates.controls(player, i)) && (@db.get(i).name.include?(name)))
              Interface.do_notify(player, "#{@db.get(i).name}(##{i})")
            end
        end
        Interface.do_notify(player, "***End of List***")
      end
    end

    private

    def look_contents(player, loc, contents_name)
        # check to see if he can see the location 
        can_see_loc = (!is_dark(loc) || r_truthify(@predicates.controls(player, loc)))
    
        # check to see if there is anything there
        can_see_something = enum(@db.get(loc).contents).any? {|thing| r_truthify(@predicates.can_see(player, thing, can_see_loc)) }
        if (can_see_something)
            # something exists!  show him everything 
            Interface.do_notify(player, contents_name)
            enum(@db.get(loc).contents).each do |thing|
              if (r_truthify(@predicates.can_see(player, thing, can_see_loc)))
                  notify_name(player, thing)
              end
            end
        end
    end

    def notify_name(player, thing)
        if (r_truthify(@predicates.controls(player, thing)))
          # tell him the number
          Interface.do_notify(player, "#{@utils.getname(thing)}(##{thing})")
        else
          # just tell him the name
          Interface.do_notify(player, @utils.getname(thing))
        end
    end

    def look_simple(player, thing)
        if (@db.get(thing).description)
          Interface.do_notify(player, @db.get(thing).description)
        else
          Interface.do_notify(player, "You see nothing special.")
        end
    end

    def flag_description(thing)
      description = "Type: "
      case typeof(thing)
          when TYPE_ROOM then description << "Room"
          when TYPE_EXIT then description << "Exit"
          when TYPE_THING then description << "Thing"
          when TYPE_PLAYER then description << "Player"
          else description << "***UNKNOWN TYPE***"
      end

      if ((@db.get(thing).flags & ~TYPE_MASK) != 0)
        # print flags 
        description << " Flags:"
        description << " WIZARD" if (is_wizard(thing))
        description << " STICKY" if (is_sticky(thing))
        description << " DARK" if (is_dark(thing))
        description << " LINK_OK" if (is_link_ok(thing))
        description << " TEMPLE" if (is_temple(thing))
      end

      description
    end

  end
end