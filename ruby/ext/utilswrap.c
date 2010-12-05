#include "ruby.h"
#include "db.h"
#include "utils.h"
#include "tinymud.h"

static VALUE utils_class;

void Init_utils()
{   
    utils_class = rb_define_class_under(tinymud_module, "Utils", rb_cObject);
}
