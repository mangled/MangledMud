module Helpers

  # FOR NOW - I have pasted in defines.rb to this, its a kludge, ideally
  # and with hindsight I should have put these into a Defines module
  # I will look at fixing this, once I have predicates and speech.c ported.
  # - Matthew

  PENNY_RATE  = 10	# 1/chance of getting a penny per room

  # Flags
  TYPE_ROOM =	0x0
  TYPE_THING = 0x1
  TYPE_EXIT =	0x2
  TYPE_PLAYER = 0x3
  NOTYPE	= 0x7
  TYPE_MASK = 0x7
  ANTILOCK =	0x8
  WIZARD = 0x10
  LINK_OK	= 0x20
  DARK = 0x40
  TEMPLE = 0x80
  STICKY = 0x100

  # Dbref values
  NOTHING = -1
  AMBIGUOUS = -2
  HOME = -3
  
  # Special dbref positions
  PLAYER_START = 0

  # Minimum cost to create various things */
  OBJECT_COST = 10
  EXIT_COST = 1
  LINK_COST = 1
  ROOM_COST = 10
  
  # amount at which temple stops being so profitable
  MAX_PENNIES = 10000
  
  # cost to do a scan
  LOOKUP_COST = 1

  # magic cookies
  NOT_TOKEN = '!'
  LOOKUP_TOKEN = '*'
  NUMBER_TOKEN = '#'

  # magic command cookies
  SAY_TOKEN  = '"'
  POSE_TOKEN = ':'

  # Maximum amount an object can be worth
  MAX_OBJECT_ENDOWMENT = 100

  # Match messages	
  NOMATCH_MESSAGE = "I don't see that here."
  AMBIGUOUS_MESSAGE = "I don't know which one you mean!"
  
  # Delimeter for lists of exit aliases
  EXIT_DELIMITER = ';'
  
  # Costs of kill command
  KILL_BASE_COST = 100 # prob = expenditure/KILL_BASE_COST
  KILL_MIN_COST = 10
  KILL_BONUS = 50	# paid to victim

  # We will need to use this quite a bit!
  # Convert true/false back to 1/0 for c-truth tests
  def c_truthify(value)
    value ? 1 : 0
  end

  # We will need to use this quite a bit!
  # Given a c truth value return a ruby truth value
  def r_truthify(value)
    value == 0 ? false : true
  end

  # We should make these methods on the db's item...
  ##################################################

  # Build an enumerator which loops from dbref, through its .next links
  def enum(dbref)
    Enumerator.new do |yielder|
      while (dbref != NOTHING)
        yielder.yield dbref
        dbref = @db.get(dbref).next
      end
    end
  end

  # Warning: These return ruby true/false, or the mask value

  # Was defined in db.h
  def is_player(item)
    ((@db.get(item).flags & TYPE_MASK) == TYPE_PLAYER)
  end

  def is_thing(item)
    ((@db.get(item).flags & TYPE_MASK) == TYPE_THING)
  end

  def is_temple(item)
    ((@db.get(item).flags & TEMPLE) != 0)
  end

  def is_sticky(item)
    ((@db.get(item).flags & STICKY) != 0)
  end

  # Was defined in db.h
  def typeof(item)
    (@db.get(item).flags & TYPE_MASK)
  end

  # Was defined in db.h
  def is_wizard(item)
    ((@db.get(item).flags & WIZARD) != 0)
  end

  # Was defined in db.h
  def is_dark(item)
    ((@db.get(item).flags & DARK) != 0)
  end

  # Was defined in db.h
  def getloc(thing)
    @db.get(thing).location
  end
end