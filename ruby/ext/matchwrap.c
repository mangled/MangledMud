#include "ruby.h"
#include "db.h"
#include "predicates.h"
#include "tinymud.h"

static VALUE match_class;

void Init_match()
{   
    match_class = rb_define_class_under(tinymud_module, "Match", rb_cObject);
}
