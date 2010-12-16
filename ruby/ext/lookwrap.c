#include "ruby.h"
#include "db.h"
#include "look.h"
#include "tinymud.h"

static VALUE look_class;

void Init_look()
{   
    look_class = rb_define_class_under(tinymud_module, "Look", rb_cObject);
}
