#include "ruby.h"
#include "db.h"
#include "move.h"
#include "tinymud.h"

static VALUE move_class;

static VALUE do_moveto(VALUE self, VALUE what, VALUE where)
{
    (void) self;
    dbref what_ref = FIX2INT(what);
    dbref where_ref = FIX2INT(where);
    moveto(what_ref, where_ref);
    return Qnil;
}

void Init_move()
{   
    move_class = rb_define_class_under(tinymud_module, "Move", rb_cObject);
    rb_define_method(move_class, "moveto", do_moveto, 2);
}
