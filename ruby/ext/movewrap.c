#include "ruby.h"
#include "db.h"
#include "move.h"
#include "tinymud.h"

static VALUE move_class;

void Init_move()
{   
    move_class = rb_define_class_under(tinymud_module, "Move", rb_cObject);
}
