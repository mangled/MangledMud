# TinyMud Ruby Port Makefile
topdir = /usr/lib/ruby/1.8/i486-linux
VPATH = $(srcdir):$(topdir)
CC = gcc
CFLAGS   = -O -g -pipe -Wall -Wextra -Wwrite-strings
INCFLAGS = -I. -I$(topdir)
RM = rm -f
SRCS = db.c player.c stringutil.c predicates.c utils.c speech.c match.c dbwrap.c playerwrap.c predicateswrap.c tinymud.c
OBJS = db.o player.o stringutil.o predicates.o utils.o speech.o match.o dbwrap.o playerwrap.o predicateswrap.o tinymud.o
SOS  = tinymud.so
#SOS  = db.so player.so predicates.so
all: $(SOS)

clean:
	@-$(RM) $(OBJS)
	@-$(RM) $(SOS)

.c.o:
	$(CC) $(INCFLAGS) $(CFLAGS) -c $<

tinymud.so : $(OBJS) Makefile
	@-$(RM) $@
	$(CC) -shared -o $@ $(OBJS)

$(OBJS): ruby.h defines.h
