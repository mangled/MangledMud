module TinyMud
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
end
