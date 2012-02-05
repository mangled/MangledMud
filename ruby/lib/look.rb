require_relative '../test/include'
require_relative './helpers.rb'

# ** Partially ported to allow move.c to be ported **
module TinyMud
  class Look
    include Helpers

    def initialize(db)
      @db = db
      @predicates = Predicates.new(@db)
      @utils = Utils.new(@db)
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

  end
end