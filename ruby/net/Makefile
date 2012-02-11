#
# Whatever you put in for $(CC) must be able to grok ANSI C.
#
CC=gcc
OPTIM= -O -g -pipe -Wall -Wextra -Werror -Wwrite-strings
# 
# To log failed commands (HUH's) to stderr, include -DLOG_FAILED_COMMANDS
# To restricted object-creating commands to users with the BUILDER bit,
#   include -DRESTRICTED_BUILDING
# To log all commands, include -DLOG_COMMANDS
#
DEFS= -DLOG_FAILED_COMMANDS
CFLAGS= $(OPTIM) $(DEFS)

# Everything except interface.c --- allows for multiple interfaces
CFILES= game.c

# .o versions of above
OFILES= game.o

# Files in the standard distribution
DISTFILES= $(CFILES) config.h interface.h \
	interface.c \
	Makefile

OUTFILES= netmud

all: netmud

netmud: interface.o $(OFILES)
	$(CC) $(CFLAGS) -o netmud interface.o $(OFILES)

clean:
	-rm -f *.o a.out $(OUTFILES)

# DO NOT REMOVE THIS LINE OR CHANGE ANYTHING AFTER IT #
game.o: game.c interface.h
interface.o: interface.c interface.h config.h

