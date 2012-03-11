require_relative 'helpers'

module MangledMud
  class Look
    include Helpers

    def initialize(db, notifier)
      @db = db
      @notifier = notifier
      @predicates = Predicates.new(@db, notifier)
      @utils = Utils.new(@db)
      @match = Match.new(@db, notifier)
    end

    def look_room(player, loc)
      # tell him the name, and the number if he can link to it
      if (@predicates.can_link_to(player, loc))
        @notifier.do_notify(player, "#{@utils.getname(loc)} (##{loc})")
      else
        @notifier.do_notify(player, @utils.getname(loc))
      end

      # tell him the description
      @notifier.do_notify(player, @db[loc].description) if (@db[loc].description)

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
            look_contents(player, thing, Phrasebook.lookup('carrying-list'))
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

      if (!@predicates.can_link(player, thing))
        @notifier.do_notify(player, Phrasebook.lookup('can-only-examine-owned'))
        return
      end

      r = @db[thing]
      @notifier.do_notify(
      player,
      "#{@utils.getname(thing)}(##{thing}) [#{@utils.getname(r.owner)}] " +
      "#{Phrasebook.lookup('key')} #{(r.flags & ANTILOCK) != 0 ? NOT_TOKEN : ' '}" +
      "#{@utils.getname(r.key)}(##{r.key}) #{Phrasebook.lookup('pennies')} " +
      "#{r.pennies} #{flag_description(thing)}"
      )

      @notifier.do_notify(player, r.description) if (r.description)

      if (r.fail)
        @notifier.do_notify(player, Phrasebook.lookup('fail', r.fail))
      end
      if (r.succ)
        @notifier.do_notify(player, Phrasebook.lookup('success', r.succ))
      end
      if (r.ofail)
        @notifier.do_notify(player, Phrasebook.lookup('ofail', r.ofail))
      end
      if (r.osucc)
        @notifier.do_notify(player, Phrasebook.lookup('osucc', r.osucc))
      end

      # show him the contents
      if (r.contents != NOTHING)
        @notifier.do_notify(player, Phrasebook.lookup('contents'))
        enum(r.contents).each do |item|
          notify_name(player, item)
        end
      end

      case typeof(thing)
      when TYPE_ROOM
        # tell him about exits
        if (r.exits != NOTHING)
          @notifier.do_notify(player, Phrasebook.lookup('exits'))
          enum(r.exits).each {|exit| notify_name(player, exit) }
        else
          @notifier.do_notify(player, Phrasebook.lookup('no-exits'))
        end

        # print dropto if present
        if (r.location != NOTHING)
          @notifier.do_notify(player, Phrasebook.lookup('dropped-go-to', @utils.getname(r.location), r.location))
        end
      when TYPE_THING # Fixme - This is a repeat of the TYPE_PLAYER check, no ruby case drop-through!!!!
        # print home
        @notifier.do_notify(player, Phrasebook.lookup('home', @utils.getname(r.exits), r.exits))

        # print location if player can link to it
        if (r.location != NOTHING &&
          (@predicates.controls(player, r.location) ||
          @predicates.can_link_to(player, r.location))
          )
          @notifier.do_notify(player, Phrasebook.lookup('location', @utils.getname(r.location), r.location))
        end
      when TYPE_PLAYER
        # print home
        @notifier.do_notify(player, Phrasebook.lookup('home', @utils.getname(r.exits), r.exits))

        # print location if player can link to it
        if (r.location != NOTHING &&
          (@predicates.controls(player, r.location) ||
          @predicates.can_link_to(player, r.location))
          )
          @notifier.do_notify(player, Phrasebook.lookup('location', @utils.getname(r.location), r.location))
        end
      when TYPE_EXIT
        # print destination
        case r.location
        when NOTHING
        when HOME
          @notifier.do_notify(player, Phrasebook.lookup('dest-home'))
        else
          if room?(r.location)
            @notifier.do_notify(player, Phrasebook.lookup('dest', @utils.getname(r.location), r.location))
          else
            @notifier.do_notify(player, Phrasebook.lookup('carried-by', @utils.getname(r.location), r.location))
          end
        end
      end
    end

    def do_score(player)
      if @db[player].pennies == 1
        @notifier.do_notify(player, Phrasebook.lookup('you-have-a-penny'))
      else
        @notifier.do_notify(player, Phrasebook.lookup('you-have-pennies', @db[player].pennies))
      end
    end

    def do_inventory(player)
      thing = @db[player].contents
      if (thing == NOTHING)
        @notifier.do_notify(player, Phrasebook.lookup('carrying-nothing'))
      else
        @notifier.do_notify(player, Phrasebook.lookup('carrying'))
        enum(thing).each do |item|
          notify_name(player, item)
        end
      end
      do_score(player)
    end

    def do_find(player, name)
      if (!@predicates.payfor(player, LOOKUP_COST))
        @notifier.do_notify(player, Phrasebook.lookup('too-poor'))
      else
        if name
          0.upto(@db.length - 1) do |i|
            # Note: this isn't the same code as the original stringutil, fix
            if (!exit?(i) && @predicates.controls(player, i) && (@db[i].name.include?(name)))
              @notifier.do_notify(player, "#{@db[i].name}(##{i})")
            end
          end
        end
        @notifier.do_notify(player, Phrasebook.lookup('end-of-list'))
      end
    end

    private

    def look_contents(player, loc, contents_name)
      # check to see if he can see the location
      can_see_loc = (!is_dark(loc) || @predicates.controls(player, loc))

      # check to see if there is anything there
      can_see_something = enum(@db[loc].contents).any? {|thing| @predicates.can_see(player, thing, can_see_loc) }
      if (can_see_something)
        # something exists!  show him everything
        @notifier.do_notify(player, contents_name)
        enum(@db[loc].contents).each do |thing|
          if (@predicates.can_see(player, thing, can_see_loc))
            notify_name(player, thing)
          end
        end
      end
    end

    def notify_name(player, thing)
      if (@predicates.controls(player, thing))
        # tell him the number
        @notifier.do_notify(player, "#{@utils.getname(thing)}(##{thing})")
      else
        # just tell him the name
        @notifier.do_notify(player, @utils.getname(thing))
      end
    end

    def look_simple(player, thing)
      if (@db[thing].description)
        @notifier.do_notify(player, @db[thing].description)
      else
        @notifier.do_notify(player, Phrasebook.lookup('see-nothing'))
      end
    end

    def flag_description(thing)
      description = Phrasebook.lookup('type') + " "
      case typeof(thing)
      when TYPE_ROOM then description << Phrasebook.lookup('type-room')
      when TYPE_EXIT then description << Phrasebook.lookup('type-exit')
      when TYPE_THING then description << Phrasebook.lookup('type-thing')
      when TYPE_PLAYER then description << Phrasebook.lookup('type-player')
      else description << Phrasebook.lookup('type-unknown')
      end

      if ((@db[thing].flags & ~TYPE_MASK) != 0)
        # print flags
        description << (" " + Phrasebook.lookup('flags'))
        description << (" " + Phrasebook.lookup('flag-wizard')) if (is_wizard(thing))
        description << (" " + Phrasebook.lookup('flag-sticky')) if (is_sticky(thing))
        description << (" " + Phrasebook.lookup('flag-dark')) if (is_dark(thing))
        description << (" " + Phrasebook.lookup('flag-link-ok')) if (is_link_ok(thing))
        description << (" " + Phrasebook.lookup('flag-temple')) if (is_temple(thing))
      end

      description
    end

  end
end
