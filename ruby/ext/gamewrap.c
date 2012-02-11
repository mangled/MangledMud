#include "ruby.h"
#include "db.h"
#include "game.h"
#include "interface.h"
#include "tinymud.h"

VALUE game_class;

static VALUE do_process_command(VALUE self, VALUE player, VALUE command)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* command_s = strdup("\0");
    if (command != Qnil) {
        command_s = StringValuePtr(command);
    }
    process_command(player_ref, command_s);
    return Qnil;
}

static VALUE do_initialize(VALUE self, VALUE db)
{
	(void) self;
	(void) db;
    return Qnil;
}

static VALUE do_do_dump(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    do_dump(player_ref);
    return Qnil;
}

static VALUE do_dump_database_to_file(VALUE self, VALUE filename)
{
    (void) self;
    char* name_s = strdup("\0");
    if (filename != Qnil) {
        name_s = StringValuePtr(filename);
    }
    dump_database_to_file(name_s);
    return Qnil;
}

static VALUE do_set_dumpfile_name(VALUE self, VALUE filename)
{
    (void) self;
    char* name_s = strdup("\0");
    if (filename != Qnil) {
        name_s = StringValuePtr(filename);
    }
    set_dumpfile_name(name_s);
    return Qnil;
}

/* Used to allow mocking of all random calls */
static VALUE do_do_rand(VALUE self)
{
    (void) self;
    /* Always return "1" unless we stub it out and return a chosen value */
    return INT2FIX(1);
}

void Init_game()
{   
    game_class = rb_define_class_under(tinymud_module, "Game", rb_cObject);
    rb_define_module_function(game_class, "dump_database_to_file", do_dump_database_to_file, 1);
    rb_define_module_function(game_class, "set_dumpfile_name", do_set_dumpfile_name, 1);
    rb_define_module_function(game_class, "do_rand", do_do_rand, 0);
    rb_define_method(game_class, "process_command", do_process_command, 2);
    rb_define_method(game_class, "do_dump", do_do_dump, 1);
	rb_define_method(game_class, "initialize", do_initialize, 1);
}
