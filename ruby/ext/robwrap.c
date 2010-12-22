#include "ruby.h"
#include "db.h"
#include "rob.h"
#include "tinymud.h"

static VALUE rob_class;

void Init_rob()
{   
    rob_class = rb_define_class_under(tinymud_module, "Rob", rb_cObject);
}
