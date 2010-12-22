#include "ruby.h"
#include "db.h"
#include "set.h"
#include "tinymud.h"

static VALUE set_class;

void Init_set()
{   
    set_class = rb_define_class_under(tinymud_module, "Set", rb_cObject);
}
