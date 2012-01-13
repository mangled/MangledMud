# TinyMud Ruby Port Makefile
############################
# Note, this is hardwired to be run from the test directory

# Include environmental variables, see make.rb
include env

# Location of source files, and output directory
IN_DIR =../src
OUT_DIR=../obj
EXT_DIR=../ext

# Compiler flags
CC = gcc
CFLAGS = -m64 -fPIC -O -g -pipe -Wall -Wextra -Wwrite-strings
INCFLAGS = -I. -I$(RUBY) -I$(IN_DIR) -I$(ARCH)
VPATH = $(RUBY):$(IN_DIR):$(OUT_DIR)

# Some commands
RM = rm -f
RMD = rmdir

# Sources that have been wrapped with extensions
SRCS = db.c player.c stringutil.c predicates.c utils.c speech.c match.c move.c look.c create.c set.c rob.c wiz.c game.c help.c

# Extension wrappers
TSRC = dbwrap.c playerwrap.c predicateswrap.c matchwrap.c utilswrap.c speechwrap.c movewrap.c lookwrap.c createwrap.c setwrap.c robwrap.c wizwrap.c stringutilwrap.c gamewrap.c helpwrap.c tinymud.c

# Objects produced by the above
OBJS = db.o player.o stringutil.o predicates.o utils.o speech.o match.o move.o look.o create.o set.o rob.o wiz.o game.o help.o dbwrap.o playerwrap.o predicateswrap.o matchwrap.o utilswrap.o speechwrap.o movewrap.o lookwrap.o createwrap.o setwrap.o robwrap.o wizwrap.o stringutilwrap.o gamewrap.o helpwrap.o tinymud.o

# Where the intermediate object files will go
OUT_OBJS = $(addprefix $(OUT_DIR)/,$(OBJS))
OUT_GCDA = $(addprefix $(OUT_DIR)/,$(patsubst %.o,%.gcda,$(OBJS)))
OUT_GCNO = $(addprefix $(OUT_DIR)/,$(patsubst %.o,%.gcno,$(OBJS)))

# The final shared library
LIB=./tinymud.so

# Ensure all (w/o coverage is the default goal)
.DEFAULT_GOAL := all

# Rules
# Only when building with coverage (i.e. the coverage target)
coverage: COVFLAGS = -fprofile-arcs -ftest-coverage
coverage: COVLINK = -lgcov
coverage: $(LIB)

all: $(LIB)

# Paranoid deletion over rm *!
clean:
	@-$(RM) $(OUT_OBJS)
	@-$(RM) $(OUT_GCDA)
	@-$(RM) $(OUT_GCNO)
	@-$(RM) $(LIB)
	@-$(RMD) $(OUT_DIR)

$(OUT_DIR)/%.o : $(EXT_DIR)/%.c
	$(CC) $(INCFLAGS) $(CFLAGS) $(COVFLAGS) -c $< -o $@

$(OUT_DIR)/%.o : $(IN_DIR)/%.c
	$(CC) $(INCFLAGS) $(CFLAGS) $(COVFLAGS) -c $< -o $@

$(LIB) : $(OUT_OBJS) Makefile env
	@-$(RM) $@
	$(CC) -shared -o $@ $(OUT_OBJS) $(COVLINK)

$(OUT_OBJS): | $(OUT_DIR)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)
