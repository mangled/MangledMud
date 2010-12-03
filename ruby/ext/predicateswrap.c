#include "ruby.h"
#include "db.h"
#include "predicates.h"
#include "tinymud.h"

static VALUE predicates_class;

static VALUE do_can_link_to(VALUE self, VALUE who_ref, VALUE where_ref)
{
    (void) self;
    dbref who = FIX2INT(who_ref);
    dbref where = FIX2INT(where_ref);
    return INT2FIX(can_link_to(who, where));
}

static VALUE do_could_doit(VALUE self, VALUE player, VALUE thing)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref thing_ref = FIX2INT(thing);
    return INT2FIX(could_doit(player_ref, thing_ref));
}

static VALUE do_can_doit(VALUE self, VALUE player, VALUE thing, VALUE default_fail_msg)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref thing_ref = FIX2INT(thing);
    const char* fail_msg = STR2CSTR(default_fail_msg);
    return INT2FIX(can_doit(player_ref, thing_ref, fail_msg));
}

void Init_predicates()
{   
    predicates_class = rb_define_class_under(tinymud_module, "Predicates", rb_cObject);
    rb_define_method(predicates_class, "can_link_to", do_can_link_to, 2);
    rb_define_method(predicates_class, "could_doit", do_could_doit, 2);
    rb_define_method(predicates_class, "can_doit", do_can_doit, 3);
}
