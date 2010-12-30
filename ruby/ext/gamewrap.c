#include "ruby.h"
#include "db.h"
#include "game.h"
#include "interface.h"
#include "tinymud.h"

static VALUE game_class;

static VALUE do_process_command(VALUE self, VALUE player, VALUE command)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* command_s = strdup("\0");
    if (command != Qnil) {
        command_s = STR2CSTR(command);
    }
    process_command(player_ref, command_s);
    return Qnil;
}

void Init_game()
{   
    game_class = rb_define_class_under(tinymud_module, "Game", rb_cObject);
    rb_define_method(game_class, "process_command", do_process_command, 2);
}
