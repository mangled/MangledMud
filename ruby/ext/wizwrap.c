#include "ruby.h"
#include "db.h"
#include "wiz.h"
#include "tinymud.h"

static VALUE wiz_class;

void Init_wiz()
{   
    wiz_class = rb_define_class_under(tinymud_module, "Wiz", rb_cObject);
}
