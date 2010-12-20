#include "ruby.h"
#include "db.h"
#include "create.h"
#include "tinymud.h"

static VALUE create_class;

void Init_create()
{   
    create_class = rb_define_class_under(tinymud_module, "Create", rb_cObject);
}
