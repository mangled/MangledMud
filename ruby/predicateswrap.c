#include "ruby.h"
#include "db.h"
#include "predicates.h"

static VALUE tinymud_module;
static VALUE predicates_class;

static VALUE do_can_link_to(VALUE self, VALUE who_ref, VALUE where_ref)
{
    (void) self;
    dbref who = FIX2INT(who_ref);
    dbref where = FIX2INT(where_ref);
    return INT2FIX(can_link_to(who, where));
}

void Init_predicates()
{
	tinymud_module = rb_define_module("TinyMud");
    
    predicates_class = rb_define_class_under(tinymud_module, "Predicates", rb_cObject);
    rb_define_method(predicates_class, "can_link_to", do_can_link_to, 2);
}
