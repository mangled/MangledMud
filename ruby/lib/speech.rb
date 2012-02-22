require_relative 'helpers'

module TinyMud
  class Speech
    include Helpers

    def initialize(db)
      @db = db
    end

    def reconstruct_message(arg1, arg2)
      (arg2 and !arg2.empty?) ? "#{arg1} = #{arg2}" : arg1
    end

    def do_say(player, arg1, arg2)
      loc = getloc(player)
      return if (loc == NOTHING)

      # notify everybody
      message = reconstruct_message(arg1, arg2)
      Interface.do_notify(player, Phrasebook.lookup('you-say', message))
      notify_except(@db[loc].contents, player, Phrasebook.lookup('someone-says', @db[player].name, message))
    end
    
    def do_pose(player, arg1, arg2)
      loc = getloc(player)
      return if (loc == NOTHING)

      # notify everybody
      message = reconstruct_message(arg1, arg2)
      notify_except(@db[loc].contents, NOTHING, "#{@db[player].name} #{message}")
    end
    
    def do_wall(player, arg1, arg2)      
      if (is_wizard(player))
        message = reconstruct_message(arg1, arg2)
        $stderr.puts("WALL from #{@db[player].name}(#{player}): #{message}")
        message = Phrasebook.lookup('someone-shouts', @db[player].name, message)
        0.upto(@db.length() - 1) {|i| Interface.do_notify(i, message) if (player?(i)) }
      else
        Interface.do_notify(player, Phrasebook.lookup('what-wall'))
      end
    end
    
    def do_gripe(player, arg1, arg2)
      loc = @db[player].location
      message = reconstruct_message(arg1, arg2)
      $stderr.puts("GRIPE from #{@db[player].name}(#{player}) in #{Utils.new(@db).getname(loc)}(#{loc}): #{message}")
      Interface.do_notify(player, Phrasebook.lookup('complaint-noted'))
    end
    
    def do_page(player, arg1)
      target = Player.new(@db).lookup_player(arg1)
      if (!Predicates.new(@db).payfor(player, LOOKUP_COST))
        Interface.do_notify(player, Phrasebook.lookup('too-poor'))
      elsif (target == NOTHING)
        Interface.do_notify(player, Phrasebook.lookup('unknown-name'))
      else
        message = Phrasebook.lookup('someone-looking-for-you', @db[player].name, @db[@db[player].location].name)
        Interface.do_notify(target, message)
        Interface.do_notify(player, Phrasebook.lookup('message-sent'))
      end
    end

    def notify_except(first, exception, msg)
      enum(first).each do |i|
        if (is_player(i) && (i != exception))
            Interface.do_notify(i, msg)
        end
      end
    end

  end
end
