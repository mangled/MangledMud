# TinyMud Ruby Port Makefile
RUBY = /usr/lib/ruby/1.8/i486-linux
IN_DIR =../src
OUT_DIR=../obj
EXT_DIR=../ext
VPATH = $(RUBY):$(IN_DIR):$(OUT_DIR)
CC = gcc
CFLAGS   = -O -g -pipe -Wall -Wextra -Wwrite-strings
INCFLAGS = -I. -I$(RUBY) -I$(IN_DIR)
RM = rm -f
RMD = rmdir
# This is rubbish, tidy up!!!
SRCS = db.c player.c stringutil.c predicates.c utils.c speech.c match.c move.c look.c create.c set.c rob.c wiz.c
TSRC = dbwrap.c playerwrap.c predicateswrap.c matchwrap.c utilswrap.c speechwrap.c movewrap.c lookwrap.c createwrap.c setwrap.c robwrap.c wizwrap.c stringutilwrap.c tinymud.c
OBJS = db.o player.o stringutil.o predicates.o utils.o speech.o match.o move.o look.o create.o set.o rob.o wiz.o dbwrap.o playerwrap.o predicateswrap.o matchwrap.o utilswrap.o speechwrap.o movewrap.o lookwrap.o createwrap.o setwrap.o robwrap.o wizwrap.o stringutilwrap.o tinymud.o
OUT_OBJS = $(addprefix $(OUT_DIR)/,$(OBJS))
LIB=./tinymud.so

all: $(LIB)

clean:
	@-$(RM) $(OUT_OBJS)
	@-$(RM) $(LIB)
	@-$(RMD) $(OUT_DIR)

$(OUT_DIR)/%.o : $(EXT_DIR)/%.c
	$(CC) $(INCFLAGS) $(CFLAGS) -c $< -o $@

$(OUT_DIR)/%.o : $(IN_DIR)/%.c
	$(CC) $(INCFLAGS) $(CFLAGS) -c $< -o $@

$(LIB) : $(OUT_OBJS) Makefile
	@-$(RM) $@
	$(CC) -shared -o $@ $(OUT_OBJS)

$(OUT_DIR):
	test -d $(OUT_DIR) || mkdir $(OUT_DIR)

$(OUT_OBJS): ruby.h defines.h $(OUT_DIR)
