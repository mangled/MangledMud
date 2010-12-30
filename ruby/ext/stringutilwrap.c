#include "ruby.h"
#include "db.h"
#include "stringutil.h"
#include "tinymud.h"

static VALUE stringutil_class;

void Init_stringutil()
{   
    stringutil_class = rb_define_class_under(tinymud_module, "StringUtil", rb_cObject);
}
