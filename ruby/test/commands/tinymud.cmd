# Script designed to test all of tinymud's commands and responses
#################################################################
# todo - errors, e.g. go to missing exit, pick up missing thing

# NOTE: Might be worth upgrading the tool to change (n) to the players name?

# Three people are enough (I think)
###################################
# Wizard and limbo are present from the start

!create_player mat bar
!create_player bob bar

mat>@password bar=bar
mat>@password boo=boo

mat>@describe me=Very handsome
bob>@describe me=Strange but nice

mat> help
bob> gripe I'm clueless
mat> news

mat>look bob
bob>look wizard

wizard> look
mat> look
bob> look

# The wizard will make a room first (nobody else has rights, they can create and dig though)
wizard> @wall I'm a wizard
wizard> @dig the lounge
wizard> @open n;lounge={the lounge}
wizard> go lounge
wizard> @open s;limbo=0
wizard> go limbo
wizard> examine n
wizard> @describe n=A way out of limbo
wizard> @success n=You escape
wizard> @osuccess n=Ping

# Mat will be able to create stuff once he gets a link...
mat> move n
wizard> @teleport #4
wizard> @open e;east
wizard> say link east opened!
mat> look
mat> @dig mat's place
wizard> give 100=mat
wizard> give mat=100
mat> @dig mat's place
mat> @link e={mat's place}
mat> examine east
mat> go east
mat> @describe here=A lovely snug den for Mat to sleep in
mat> @open s={the lounge}
wizard> @set here=LINK_OK
mat> @open s={the lounge}
mat> @create desk
mat> @set desk=me
mat> @lock desk=me
mat> examine desk
mat> @describe desk=A small writing desk covered in paper
mat> @open paper
mat> @describe paper=The memoirs of matthew
mat> @lock paper=me
mat> look paper
mat> @fail paper=Its matthew's
mat> @ofail paper=Tried to take matthew's memoirs!
mat> @link me=paper
mat> @link me=here
mat> examine here
mat> @create cheese
mat> @describe cheese=Lovely and whiffy
mat> @success cheese=You take the smelly cheese
mat> @link cheese={the lounge}
mat> examine here
mat> @name cheese=strong cheese
mat> look
mat> i
mat> drop desk
mat> look
mat> score
mat> @open down=home
mat> examine down

# Wizard makes an empty room
wizard> @dig empty room
wizard> @open down={empty room}
wizard> go down
wizard> @open up={the lounge}
wizard> @link here={the lounge}
wizard> examine here
wizard> go up

# Wizard makes a temple and dark crypt
wizard> @dig temple
wizard> @open up={temple}
wizard> go up
wizard> @open down={the lounge}
wizard> @describe down=To the funky lounge
wizard> @set here=TEMPLE
wizard> @describe here=The temple of DOOM, sacrifices always welcome
wizard> look
wizard> @dig the crypt
wizard> @open w;west={the crypt}
wizard> examine here
wizard> go west
wizard> @describe here=A dark place
wizard> look
wizard> @set here=DARK
wizard> @open chair
wizard> @describe chair=The chair of scary stuff
wizard> look
wizard> @open e={temple}
wizard> @force kate=get tree
wizard> @force bob=look
wizard> give bob=10
wizard> go e
wizard> go down
wizard> examine #{strong cheese}
wizard> examine *mat

# Bob goes walkabout
bob> go n
bob> look
bob> page mat=ooohhh spooky
wizard> give bob=13
bob> page mat=ooohhh spooky
bob> go up
bob> @create socks
bob> @describe socks=From granny with love
bob> @lock socks=me
bob> @fail socks=Why would you want to?
bob> @ofail socks=is getting smelly hands
bob> @osucc socks=picks up the stripy socks
bob> @success socks=You got a lovely pair of socks
bob> @link socks={the lounge}
bob> drop socks
wizard> look
wizard> look socks
wizard> examine socks
bob> go w
bob> take chair
bob> take fish
bob> go e
bob> examine here
bob> look down
bob> go down
wizard> take socks
bob> @unlock socks=
wizard> take socks
bob> go e
bob> paper
bob> look paper
bob> look here
bob> i
bob> @find mat
bob> @find sock
bob> @find sock
mat> give bob=10
mat> give bob=-5
wizard> go e
wizard> give bob=20
bob> @create socks
bob> @describe=My second favourite pair!
bob> drop socks
wizard> drop socks
bob> get so
bob> get w
mat> @force bob=look

# Can't put at top as one of the references must be absolute - fix this (at some point)
!create_player mark bar

mark> go n
mark> go east
mat> give ma=5
mat> give socks=5
mat> give bob=100000
mat> give bob=500
bob> rob ma
bob> rob socks
bob> rob mat

mat> @teleport socks={the lounge}
wizard> @teleport mat=#{the lounge}
wizard> @teleport ma=here
bob> @stats
wizard> @stats

# Build another room to check sticky room and ambig move
mat> move home
mat> @dig mats bedroom
mat> @open sleep={mats bedroom}
mat> go sleep
mat> @link here={mat's place}
mat> @open wake={mat's place}
mat> @open woken={mat's place}
mat> get wake
mat> @create pillow
mat> drop pillow
mat> @open bathroom
mat> examine
mat> examine bathroom
mat> examine here
mat> get #{bathroom}
mat> get #{bathroom}
mat> go w
wizard> get #{bathroom}
mat> drop bathroom
mat> drop bathroom
wizard> get #{bathroom}
wizard> go sleep
wizard> get #{bathroom}
wizard> get #{bathroom}
wizard> drop bathroom
wizard> go wake
mat> go wake
mat> get pillow
mat> @lock sleep=me
mat> @ofail sleep=Failed to go to sleep
mat> @fail sleep=No way, its mats room of sleep
mat> go sleep
bob> go sleep
mat> @set here=STICKY
mat> drop pillow
mat> get bathroom
mat> go wake
mat> go s
mat> drop bathroom
mat> go e
mat> @link bathroom={mats bedroom}
mat> get socks
mat> @link socks={the lounge}
mat> @link socks={mats bedroom}
mat> @set socks=STICKY
mat> examine socks
mat> go s
mat> go up
mat> drop socks
mat> go down
bob> go s
bob> take socks
wizard> go s
wizard> give bob=100000
bob> @create gold ring=100000
bob> drop gold ring
mat> get gold ring
mat> go up
mat> drop gold ring
mat> go down
bob> get gold ring
wizard> @open boing
wizard> @chown boing=bob
bob> @create twig
bob> @link twig={the lounge}
bob> @set twig=
bob> @set twig=STICKY
bob> get boing
bob> go home
bob> get twig
wizard> go up
mat> go up
bob> go n
bob> go up
bob> go w
mat> go w
wizard> go w
wizard> @dig dinge
wizard> @open n={dinge}
wizard> go n
wizard> @describe here=Rather dark, go back s
wizard> @set here=DARK
wizard> @open s={the crypt}
wizard> s
bob> go n
mat> go n
bob> go s
mat> go s
bob> go e
bob> go down
bob> go e
mat> go e
mat> go down
mat> go e
wizard> @create hat
wizard> @create wand
wizard> @link wand={temple}
wizard> @set wand=STICKY
wizard> @teleport #0
wizard> @name ear=
wizard> go n
wizard> go e
wizard> @name mark=
wizard> @name mark=mick
wizard> @name mark=mick boo
wizard> @name mark=mat bar
wizard> @name mark=mick bar
wizard> @name mick=mark bar
wizard> @name socks=home
wizard> @name socks=me
wizard> @name socks=here
wizard> @name socks=*
wizard> @name socks=#
wizard> @describe socks=Wizard socks
wizard> @fail socks=Why would you want to?
wizard> @ofail socks=is getting smelly hands
wizard> @osucc socks=picks up the stripy socks
wizard> @success socks=You got a lovely pair of socks
wizard> @describe socks=Wizard socks
wizard> @fail socks=Why would you want to?
wizard> @ofail socks=is getting smelly hands
wizard> @osucc socks=picks up the stripy socks
wizard> @success socks=You got a lovely pair of socks
wizard> @create socks
wizard> get socks
wizard> examine #26 
wizard> examine #42
wizard> @lock tree
wizard> @lock soc
wizard> @lock #26=m
mat> @create leg
mat> @open se
mat> get se
mat> @lock leg=se
mat> @lock leg=me
mat> drop leg
mark> @lock leg=me
mat> @lock leg=!mark
mat> examine leg
mark> get leg
bob> get leg
bob> @chown leg=me
wizard> get pillow
wizard> @chown pillow=dawn
wizard> @chown mark=mat
bob> @set here=DARK
bob> @set here=TEMPLE
wizard> @set me=!WIZARD
wizard> @set pillow=!TEMPLE
bob> @set me=TEMPLE
bob> @set me=DARK
bob> @set leg=!DARK
bob> @unlink e
mat> @unlink s
mat> @open sleepy
mat> @link sleepy={mats bedroom}
mat> @unlink slee
mat> @unlink here
mat> @chown sleepy=bob
wizard> @chown #{sleepy}=bob
wizard> @unlink #{sleepy}
mat> @unlink sleepy
wizard> rob
wizard> rob mat
wizard> rob mark
mat> kill
mat> kill greg
mat> kill m
mat> kill desk
mat> kill wizard
mark> kill mat
mat> kill mark
wizard> give mat=100000
mat> kill mark=100000

!create_player jim bar

wizard> kill #{jim}

!create_player greg bar
greg> go n
greg> go e

mat>@toad mark
wizard>@toad
wizard>@toad desk
wizard>@set mat=WIZARD
wizard>@toad mat
wizard>@toad bob
wizard>@toad greg
mat>@dig graveyard
mat>@dig gym
mat>@open spooky={graveyard}
mat>@open spooked={gym}
mat> @create fig
mat> @teleport fig=gr
mat> examine
mat> @teleport #{mat's place}=wizard
mat> @teleport #{spooked}=wizard
mat> @teleport #{fig}=bob
mat> @create foof
mat> @create food
mat> @teleport foo=bob
bob> i
bob> @teleport #{fig}=mat

!create_player max bar
max> go n
max> go e

mat> @teleport foof=ma

mat> drop foof
wizard> get foof
wizard> @chown foof=0
wizard> @stats
wizard> examine *mat

wizard>@set mat=!WIZARD
mat> @open
mat> @open me
mat> @open here
mat> @open me;here
mat> @open *
mat> @open #
mat> @open pit
wizard> give max=10
max> @dig max's house
max> @link pit={max's house}
wizard> give max=2
max> @link pit={max's house}
max> go pit
max> @open exit
# THIS HAS to be a BUG. It keeps making exits of the same name!
wizard> give *max=2
max> @open exit={mat's place}
mat> @set here=LINK_OK
max> @open exit={mat's place}
wizard> give *max=2
max> @open exit={mat's place}
wizard> give *max=2
max> @open exit={mat's place}
wizard> give *max=2
max> @link exit={mat's place}
max> @lock exit=me
mat> go pit
mat> @link exit={mat's place}
max> @open foo={mat's place}
mat> @link foo={mat's place}
max> @unlink foo
max> @lock foo=me
mat> @link foo={mat's place}
max> @lock here=me
mat> @link here={mat's place}
max> @link me=home
max> @dig
max> @dig home
max> @dig me
max> @dig *
max> @dig #
max> @create
max> @create home
max> @create me
max> @create *
max> @create #
max> @create bread=-1
max> @link exit=*mat
max> read
max> throw exit
mat> @create ball
mat> throw ball
max> look
max> @link me=here
max> examine here
max> examine #{max's house}

mat>@wall
mat>page felix

# These are not handled (or don't exist)???
max>quit
max>QUIT
wizard>@boot
wizard>@boot mat

# commands that don't exist
wizard>who
wizard>whisper

# LAST TODO's

# how do things get nothing? in limbo?
# TRY
wizard>@teleport #0
wizard> i
wizard> drop foof
wizard> examine #{foof}

# do a dump --> FIX THIS
#wizard>@dump
