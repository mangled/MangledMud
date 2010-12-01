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
end
