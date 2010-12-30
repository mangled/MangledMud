#include "ruby.h"
#include "db.h"
#include "game.h"
#include "tinymud.h"

static VALUE game_class;

void Init_game()
{   
    game_class = rb_define_class_under(tinymud_module, "Game", rb_cObject);
}
