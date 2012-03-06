# Tries various incorrectly formatted commands
# This test flushes out bad input handling in the game
# Its required because we pass nil instead of "" as args
#
# This assumes that the parser in game.rb will pass in nulls
# for missing params.
############################################################

# garbage
wizard>boing
wizard>boing a
wizard>boing a b

# chown
wizard>@chown
wizard>@chown a
wizard>@chown a b

# create
wizard>@create
wizard>@create a
wizard>@create a b

# describe
wizard>@describe
wizard>@describe a
wizard>@describe a b

# dig
wizard>@dig
wizard>@dig a
wizard>@dig a b

# drop
wizard>drop
wizard>drop a
wizard>drop a b

# dump
wizard>@dump
wizard>@dump a
wizard>@dump a b

# examine
wizard>examine
wizard>examine a
wizard>examine a b

# fail
wizard>@fail
wizard>@fail a
wizard>@fail a b

# find
wizard>@find
wizard>@find a
wizard>@find a b

# force
wizard>@force
wizard>@force a
wizard>@force a b

# get
wizard>get
wizard>get a
wizard>get a b

# give
wizard>give
wizard>give a
wizard>give a b

# goto
wizard>goto
wizard>goto a
wizard>goto a b

# gripe
wizard>gripe
wizard>gripe a
wizard>gripe a b

# help
wizard>help
wizard>help a
wizard>help a b

# inventory
wizard>inventory
wizard>inventory a
wizard>inventory a b

# kill
wizard>kill
wizard>kill a
wizard>kill a b

# link
wizard>@link
wizard>@link a
wizard>@link a b

# lock
wizard>@lock
wizard>@lock a
wizard>@lock a b

# look
wizard>look
wizard>look a
wizard>look a b

# move
wizard>@move
wizard>@move a
wizard>@move a b

# name
wizard>@name
wizard>@name a
wizard>@name a b

# news
wizard>news
wizard>news a
wizard>news a b

# ofail
wizard>@ofail
wizard>@ofail a
wizard>@ofail a b

# open
wizard>@open
wizard>@open a
wizard>@open a b

# osuccess
wizard>@osuccess
wizard>@osuccess a
wizard>@osuccess a b

# page
wizard>page
wizard>page a
wizard>page a b

# password
wizard>@password
wizard>@password a
wizard>@password a b

# read
wizard>read
wizard>read a
wizard>read a b

# rob
wizard>rob
wizard>rob a
wizard>rob a b

# say
wizard>say
wizard>say a
wizard>say a b

# score
wizard>score
wizard>score a
wizard>score a b

# set
wizard>@set
wizard>@set a
wizard>@set a b

# stats
wizard>@stats
wizard>@stats a
wizard>@stats a b

# success
wizard>@success
wizard>@success a
wizard>@success a b

# take
wizard>take
wizard>take a
wizard>take a b

# teleport
wizard>@teleport
wizard>@teleport a
wizard>@teleport a b

# throw
wizard>throw
wizard>throw a
wizard>throw a b

# toad
wizard>@toad
wizard>@toad a
wizard>@toad a b

# unlink
wizard>@unlink
wizard>@unlink a
wizard>@unlink a b

# unlock
wizard>@unlock
wizard>@unlock a
wizard>@unlock a b

# wall
wizard>@wall
wizard>@wall a
wizard>@wall a b

# shutdown - can't test all combinations as we explicitly stop further processing
# any more calls will raise an exception
wizard>@shutdown
