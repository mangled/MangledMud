# Linking
##########

!create_player bob bar
!create_player sam bar

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

# Make some things
wizard> give #3=100
sam> @create Cheese String
sam> @create Cheese WigWam
sam> drop cheese
sam> drop wigwam
sam> look

# TEMPLE!!!
