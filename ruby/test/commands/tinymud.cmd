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
# to-do
# sticky
# rob
# unlink
# find
# toad
# drop-to

