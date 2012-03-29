require_relative 'helpers'

module MangledMud
  
  # Handles finding (matching) "things" through searching a number of different "locations"
  # @note This follows the original code to the letter, further refactoring would make this more ruby-esque
  # @note This documentation is an overview, the code is subtle and requires inspection for nuances
  #
  # @version 1.0
  class Match
    include Helpers

    # @param [Db] db the current database instance
    # @param [Object] notifier An object with method do_notify(player_id, string), the method will be called to send notifications back to the player invoking the command/action
    def initialize(db, notifier)
      @db = db
      @notifier = notifier
    end

    # Initialize, ready for a new match to be made, match ignoring access rights for the thing being matched.
    # @note Must be called before any of the match_ methods
    #
    # @param [Number] player the database record number for the player
    # @param [String] name the name of the thing to be matched, may be nil
    # @param [Number] type the type of the thing to be matched, see {TYPE_ROOM}, {TYPE_THING}, {TYPE_EXIT}, {TYPE_PLAYER}, {NOTYPE}
    def init_match(player, name, type)
      @exact_match = NOTHING
      @last_match = NOTHING
      @match_count = 0
      @match_who = player
      @match_name = name
      @check_keys = false
      @preferred_type = type
    end

    # Initialize, ready for a new match to be made, match taking into account the players access rights for the thing being matched
    # @note Must be called before any of the match_ methods
    #
    # @param [Number] player the database record number for the player
    # @param [String] name the name of the thing to be matched, may be nil
    # @param [Number] type the type of the thing to be matched, see {TYPE_ROOM}, {TYPE_THING}, {TYPE_EXIT}, {TYPE_PLAYER}, {NOTYPE}
    def init_match_check_keys(player, name, type)
      init_match(player, name, type)
      @check_keys = true
    end

    # Match a player by name (as set in {#init_match_check_keys} or {#init_match})
    # Only an exact match is possible.
    #
    # @see #match_result
    # @see #last_match_result
    # @see #noisy_match_result
    def match_player()
      if (@match_name and @match_name[0] == LOOKUP_TOKEN && Predicates.new(@db, @notifier).payfor(@match_who, LOOKUP_COST))
        player_id = @match_name[1..-1].lstrip()
        match = Player.new(@db, @notifier).lookup_player(player_id)
        @exact_match = match if (match != NOTHING)
      end
    end

    # Match by absolute name, i.e. name is #nnn, where nnn is a database record identifier (number)
    # Only an exact match is possible. See {#init_match_check_keys} or {#init_match}.
    #
    # @see #match_result
    # @see #last_match_result
    # @see #noisy_match_result
    def match_absolute()
      match = absolute_name()
      @exact_match = match if (match != NOTHING)
    end

    # If matching on "me" then exact match on the player
    # Only an exact match is possible. See {#init_match_check_keys} or {#init_match}.
    def match_me()
      if @match_name
        @exact_match = @match_who if (@match_name.casecmp("me") == 0)
      end
    end

    # If matching on "here" then exact match on the players location
    # Only an exact match is possible. See {#init_match_check_keys} or {#init_match}.
    def match_here()
      if (@match_name and @match_name.casecmp("here") == 0 && @db[@match_who].location != NOTHING)
        @exact_match = @db[@match_who].location
      end
    end

    # Match a thing in players contents, an ambiguous match may occur
    # (if the thing is not specified by an absolute name).
    # See {#init_match_check_keys} or {#init_match}.
    #
    # @see #match_result
    # @see #last_match_result
    # @see #noisy_match_result
    def match_possession()
      match_list(@db[@match_who].contents)
    end

    # Match the player based on the contents of their location, an ambiguous match may occur
    # (if the thing is not specified by an absolute name)
    # See {#init_match_check_keys} or {#init_match}.
    #
    # @see #match_result
    # @see #last_match_result
    # @see #noisy_match_result
    def match_neighbor()
      loc = @db[@match_who].location
      if (loc != NOTHING)
        match_list(@db[loc].contents)
      end
    end

    # Match an exit based on the location of the player, an ambiguous match may occur
    # (if the exit is not specified by an absolute name)
    # See {#init_match_check_keys} or {#init_match}.
    #
    # @see #match_result
    # @see #last_match_result
    # @see #noisy_match_result
    def match_exit()
      loc = @db[@match_who].location
      if (loc != NOTHING)
        absolute = absolute_name()
        absolute = NOTHING if (!Predicates.new(@db, @notifier).controls(@match_who, absolute))

        enum(@db[loc].exits).each do |exit|
          if (exit == absolute)
            @exact_match = exit
          elsif @match_name
            @db[exit].name.split(EXIT_DELIMITER).each do |name|
              # Allow a partial match - for ambiguous matching
              if (name.downcase.strip.start_with?(@match_name.downcase))
                # ! Matthew - Modified original code -> Bug fix?
                if (@check_keys)
                  could_doit = Predicates.new(@db, @notifier).could_doit(@match_who, exit)
                  @match_count += 1 if could_doit
                else
                  @match_count += 1
                end
                # Only match exact if the names are equal
                if (@match_name.casecmp(name) == 0)
                  @exact_match = choose_thing(@exact_match, exit)
                end
              end
            end
          end
        end
      end
    end

    # Perform {#match_exit}, {#match_neighbor}, {#match_possession}, {#match_me} and {#match_here},
    # if the player is a wizard then also {#match_absolute} and {#match_player}
    def match_everything()
      match_exit()
      match_neighbor()
      match_possession()
      match_me()
      match_here()
      if (is_wizard(@match_who))
        match_absolute()
        match_player()
      end
    end

    # Get the result of calling a match command
    #
    # @return [Number] if an exact match occurred, then return the identifier of the database record that matched otherwise, return {NOTHING} or {AMBIGUOUS}
    def match_result()
      if (@exact_match != NOTHING)
        @exact_match
      else
        case @match_count
        when 0 then NOTHING
        when 1 then @last_match
        else AMBIGUOUS
        end
      end
    end

    # Return the last item matched
    # @return [Number] if a match occurred, return the identifier of the database record that matched else {NOTHING}
    def last_match_result()
      (@exact_match != NOTHING) ? @exact_match : @last_match
    end

    # The same as {#match_result}, except this uses the notifier passed to the initializer to inform the player of the match result.
    # @return [Number] if an exact match occurred, then return the identifier of the database record that matched otherwise, return {NOTHING} or {AMBIGUOUS}
    def noisy_match_result()
      match = match_result()
      case match
      when NOTHING
        @notifier.do_notify(@match_who, Phrasebook.lookup('dont-see-that'))
        NOTHING
      when AMBIGUOUS
        @notifier.do_notify(@match_who, Phrasebook.lookup('which-one'))
        NOTHING
      else
        match
      end
    end

    private

    # returns nnn if name = #nnn, else NOTHING
    def absolute_name()
      if (@match_name and @match_name[0] == NUMBER_TOKEN)
        match = @db.parse_dbref(@match_name[1..-1])
        if (match < 0 || match >= @db.length)
          return NOTHING
        else
          match
        end
      else
        NOTHING
      end
    end

    # Enumerate a list starting at first, looking for the thing to match
    def match_list(first)
      absolute = absolute_name()
      absolute = NOTHING if (!Predicates.new(@db, @notifier).controls(@match_who, absolute))

      enum(first).each do |i|
        if (i == absolute)
          @exact_match = i
          return
        elsif @match_name
          if (@db[i].name.casecmp(@match_name) == 0)
            # if there are multiple exact matches, randomly choose one
            @exact_match = choose_thing(@exact_match, i)
          else
            # Match at the start of words - There must be a neater way
            name_words = @db[i].name.split(/\s+/)
            name_words.each do |word|
              if word.downcase.start_with?(@match_name.downcase)
                @last_match = i
                @match_count += 1
                break
              end
            end
          end
        end
      end
    end

    # Given a choice of two things, pick one of them (one or both things may be NOTHING)
    def choose_thing(thing1, thing2)
      if (thing1 == NOTHING)
        return thing2
      elsif (thing2 == NOTHING)
        return thing1
      end

      if (@preferred_type != NOTYPE)
        if (typeof(thing1) == @preferred_type)
          if (typeof(thing2) != @preferred_type)
            return thing1
          end
        elsif (typeof(thing2) == @preferred_type)
          return thing2
        end
      end

      if (@check_keys)
        has1 = Predicates.new(@db, @notifier).could_doit(@match_who, thing1)
        has2 = Predicates.new(@db, @notifier).could_doit(@match_who, thing2)
        if (has1 && !has2)
          return thing1
        elsif (has2 && !has1)
          return thing2
        end
        # else fall through
      end

      return (Game.do_rand() % 2 ? thing1 : thing2)
    end
  end
end
