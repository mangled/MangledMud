# Linking
##########

!create_player bob bar
!create_player sam bar

# Looking and Talking
#####################

bob> "hello
bob> :hello
bob> look
bob> look sam
sam> @describe me=hairy
bob> look sam
# This isn't a command (in docs it is one) bob> whisper sam=boo
bob> score
bob> examine sam
bob> examine me
wizard> examine bob

# Dig a room and link it
wizard> @dig treehouse
# Create an exit north
wizard> @open n;north=4
wizard> n
wizard> @describe here=A shady leafy treetop dwelling!
bob> n

# Make a link for bob (he needs some money)
wizard> give bob=100
bob> @dig Bob's Home
wizard> @open e;east
bob> @link east=6
bob> e

# TEMPLE!!!

