require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Match
    include Helpers

    def initialize(db)
      @db = db
    end

    def init_match(player, name, type)
      @exact_match = last_match = NOTHING
      @match_count = 0
      @match_who = player
      @match_name = name
      @check_keys = false
      @preferred_type = type
    end

    def init_match_check_keys(player, name, type)
      init_match(player, name, type);
      @check_keys = true;
    end

    def match_player()
      if (@match_name[0] == LOOKUP_TOKEN && r_truthify(Predicates.new(@db).payfor(@match_who, LOOKUP_COST)))
          player_id = match_name[1..-1].lstrip()
          match = Player.new(@db).lookup_player(player_id)
          @exact_match = match if (match != NOTHING)
      end
    end

    def match_absolute()
      match = absolute_name()
      @exact_match = match if (match != NOTHING)
    end

    def match_me()
      @exact_match = @match_who if (@match_name.casecmp("me") == 0)
    end

    def match_here()
      if (@match_name.casecmp("here") == 0 && @db.get(match_who).location != NOTHING)
          @exact_match = @db.get(match_who).location
      end
    end

    def match_possession()
      match_list(@db.get(@match_who).contents)
    end

    def match_neighbor()
      loc = @db.get(@match_who).location
      if (loc != NOTHING)
          match_list(@db.get(loc).contents)
      end
    end

    def match_exit()
      loc = @db.get(@match_who).location
      if (loc != NOTHING)
        absolute = absolute_name()
        absolute = NOTHING if (!r_truthify(controls(@match_who, absolute)))

        enum(@db.get(loc).exits).each do |exit|
          if (exit == absolute)
            @exact_match = exit
          else
            @db.get(exit).name.split(EXIT_DELIMITER).each do |name|
              if (@match_name.casecmp(name.strip!) == 0)
                  # ! Matthew - Modified original code -> Bug fix?
                  if (@check_keys)
                      int exit_status = Predicates.new(@db).could_doit(match_who, exit)
                      @match_count += exit_status		     
                  else
                      @match_count += 1
                  end
                  @exact_match = choose_thing(@exact_match, exit);
              end
            end
          end
        end
      end
    end

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

    def match_result()
      if (@exact_match != NOTHING)
        exact_match
      else
        case @match_count
          when 0 then NOTHING
          when 1 then @last_match
          else AMBIGUOUS
        end
      end
    end

    def last_match_result()
      (@exact_match != NOTHING) ? @exact_match : @last_match
    end

    def noisy_match_result()
      match = match_result()
      case match
        when NOTHING
          Interface.notify(@match_who, NOMATCH_MESSAGE)
          NOTHING
        when AMBIGUOUS
          Interface.notify(@match_who, AMBIGUOUS_MESSAGE)
          NOTHING
        else
          match
      end
    end

    private

    # returns nnn if name = #nnn, else NOTHING
    def absolute_name()
      if (@match_name[0] == NUMBER_TOKEN)
          match = parse_dbref(@match_name[1..-1])
          if (match < 0 || match >= @db.length)
              return NOTHING
          else
            match
          end
      else
        NOTHING
      end
    end

    def match_list(first)
        absolute = absolute_name();
        absolute = NOTHING if (!r_truthify(Predicates.new(@db).controls(@match_who, absolute)))
    
        enum(first).each do |i|
          if (i == absolute)
              @exact_match = first
              return
          elsif (@db.get(i).name.casecmp(@match_name) == 0)
              # if there are multiple exact matches, randomly choose one
              @exact_match = choose_thing(@exact_match, i)
          elsif (@db.get(i).name.include?(@match_name)) # Matthew - This may not be correct - check original string_match (per word?)
              @last_match = i
              @match_count += 1
          end
        end
    end

    def choose_thing(thing1, thing2)   
        if (thing1 == NOTHING)
            return thing2
        elsif (thing2 == NOTHING)
            return thing1
        end
  
        if (@preferred_type != NOTYPE)
            if (typeof(thing1) == preferred_type)
                if (typeof(thing2) != preferred_type)
                    return thing1
                end
            elsif (typeof(thing2) == preferred_type)
                return thing2
            end
        end
    
        if (check_keys)
            has1 = r_truthify(Predicates.new(@db).could_doit(match_who, thing1))
            has2 = r_truthify(Predicates.new(@db).could_doit(match_who, thing2))
            if (has1 && !has2)
                return thing1
            elsif (has2 && !has1)
                return thing2
            end
            # else fall through
        end
        return (random() % 2 ? thing1 : thing2)
    end
  end
end
