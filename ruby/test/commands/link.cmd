# Linking
##########

!create_player bob bar
!create_player sam bar

# Dig a room and link it
wizard> @dig treehouse
# Create an exit north
wizard> @open n;north={treehouse}
wizard> n
wizard> @describe here=A shady leafy treetop dwelling!
bob> n

# Make a link for bob (he needs some money)
wizard> give bob=100
bob> @dig Bob's Home
wizard> @open e;east
bob> @link east={Bob's Home}
bob> e

# TEMPLE!!!
