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
CFILES= create.c game.c help.c look.c match.c move.c player.c predicates.c \
	rob.c set.c speech.c stringutil.c utils.c wiz.c db.c game.c 

# .o versions of above
OFILES= create.o game.o help.o look.o match.o move.o player.o predicates.o \
	rob.o set.o speech.o stringutil.o utils.o wiz.o db.o 

# Files in the standard distribution
DISTFILES= $(CFILES) config.h db.h externs.h interface.h match.h \
	interface.c dump.c sanity-check.c extract.c paths.c \
	help.txt small.db minimal.db restart-cmu README small.db.README \
	Makefile copyright.h

DESTDIR= /usr/asp/tinymud

OUTFILES= netmud dump paths sanity-check extract

all: extract sanity-check dump paths netmud

netmud: interface.o $(OFILES)
	-mv -f netmud netmud~
	$(CC) $(CFLAGS) -o netmud interface.o $(OFILES)

dump: dump.o utils.o db.o
	-rm -f dump
	$(CC) $(CFLAGS) -o dump dump.o utils.o db.o

sanity-check: sanity-check.o utils.o db.o
	-rm -f sanity-check
	$(CC) $(CFLAGS) -o sanity-check sanity-check.o utils.o db.o

extract: extract.o utils.o db.o
	-rm -f extract
	$(CC) $(CFLAGS) -o extract extract.o utils.o db.o

paths: paths.o db.o
	-rm -f paths
	$(CC) $(CFLAGS) -o paths paths.o db.o

clean:
	-rm -f *.o a.out core gmon.out $(OUTFILES)

dist.tar.Z: $(DISTFILES)
	tar cvf - $(DISTFILES) | compress -c > dist.tar.Z.NEW
	mv dist.tar.Z.NEW dist.tar.Z

# DO NOT REMOVE THIS LINE OR CHANGE ANYTHING AFTER IT #
create.o: create.c db.h config.h interface.h externs.h
db.o: db.c db.h
dump.o: dump.c db.h
extract.o: extract.c db.h
fix.o: fix.c db.h config.h
game.o: game.c db.h config.h interface.h match.h externs.h
help.o: help.c db.h config.h interface.h externs.h
interface.o: interface.c db.h interface.h config.h
janitor.o: janitor.c db.h config.h interface.h externs.h
look.o: look.c db.h config.h interface.h match.h externs.h
match.o: match.c db.h config.h match.h
move.o: move.c db.h config.h interface.h match.h externs.h
old.o: old.c
paths.o: paths.c db.h config.h
player.o: player.c db.h config.h interface.h externs.h
predicates.o: predicates.c db.h interface.h config.h externs.h
rob.o: rob.c db.h config.h interface.h match.h externs.h
sanity-check.o: sanity-check.c db.h config.h
set.o: set.c db.h config.h match.h interface.h externs.h
speech.o: speech.c db.h interface.h match.h config.h externs.h
stringutil.o: stringutil.c externs.h
testmain.o: testmain.c db.h interface.h
utils.o: utils.c db.h
wiz.o: wiz.c db.h interface.h match.h externs.h
config.h:
db.h:
externs.h: db.h
interface.h: db.h
match.h: db.h
