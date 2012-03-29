module MangledMud

  # The default port for the {Server}
  DEFAULT_PORT  = 4201

  # The default host for the {Server}
  DEFAULT_HOST  = "localhost"

  # The number of seconds between automated database dumping, see {Server}
  DUMP_INTERVAL = 3600

  # Flag value for type room
  TYPE_ROOM = 0x0

  # Flag value for type thing
  TYPE_THING = 0x1

  # Flag value for type exit
  TYPE_EXIT = 0x2

  # Flag value for type player
  TYPE_PLAYER = 0x3

  # Flag value for no type
  NOTYPE = 0x7

  # Flag value for type masking
  TYPE_MASK = 0x7

  # Flag value to indicate an inverted lock i.e. not ...
  ANTILOCK = 0x8

  # Flag value indicating the player is a wizard
  WIZARD = 0x10

  # Flag value indicating a link can be made from this location
  LINK_OK = 0x20

  # Flag value indicating a dark location
  DARK = 0x40

  # Flag value indicating a location is a temple
  TEMPLE = 0x80

  # Flag value indicating a thing's sticky state
  STICKY = 0x100

  # Special database value to mean nothing
  NOTHING = -1

  # Special database value to mean ambiguous (multiple matches for example)
  AMBIGUOUS = -2
  
  # Special database value to mean a players home
  HOME = -3

  # Special database value for players start location
  PLAYER_START = 0

  # Minimum cost to create an object
  OBJECT_COST = 10
  
  # Minimum cost to create an exit
  EXIT_COST = 1
  
  # Minimum cost to create a link
  LINK_COST = 1
  
  # Minimum cost to create a room
  ROOM_COST = 10

  # The amount at which a temple stops being so profitable and the maximum a player may have
  MAX_PENNIES = 10000

  # The cost to do a lookup/scan
  LOOKUP_COST = 1

  # Command token for "not", see {Look} and {Set}
  NOT_TOKEN = '!'

  # Command token for "lookup", see {Match} and {Predicates}
  LOOKUP_TOKEN = '*'

  # Command token for "numbers", see {Match} and {Predicates}
  NUMBER_TOKEN = '#'

  # Command token for "say",  see {Game#process_command}
  SAY_TOKEN  = '"'

  # Command token for "pose", see {Game#process_command}
  POSE_TOKEN = ':'

  # The delimeter for lists of exit aliases, see {Match#match_exit}
  EXIT_DELIMITER = ';'

  # The probability of a kill succeeding (expenditure/KILL_BASE_COST), see {Rob#do_kill}
  KILL_BASE_COST = 100

  # The minimum cost to kill someone, see {Rob#do_kill}
  KILL_MIN_COST = 10

  # The kill bonus paid to a victim, see {Rob#do_kill}
  KILL_BONUS = 50

  # The (1/chance) of getting a penny per room, see {Move#enter_room}
  PENNY_RATE = 10

  # The maximum amount an object can be worth
  MAX_OBJECT_ENDOWMENT = 100

  # Used to calculate the cost of endowment for an object, see {Create#endow}
  ENDOWMENT_CALCULATOR = 5
end
