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
    const char* fail_msg = StringValuePtr(default_fail_msg);
    return INT2FIX(can_doit(player_ref, thing_ref, fail_msg));
}

static VALUE do_can_see(VALUE self, VALUE player, VALUE thing, VALUE can_see_loc)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref thing_ref = FIX2INT(thing);
    int can_see_loc_ref = FIX2INT(can_see_loc);
    return INT2FIX(can_see(player_ref, thing_ref, can_see_loc_ref));
}

static VALUE do_controls(VALUE self, VALUE who, VALUE what)
{
    (void) self;
    dbref who_ref = FIX2INT(who);
    dbref what_ref = FIX2INT(what);
    return INT2FIX(controls(who_ref, what_ref));
}

static VALUE do_can_link(VALUE self, VALUE who, VALUE what)
{
    (void) self;
    dbref who_ref = FIX2INT(who);
    dbref what_ref = FIX2INT(what);
    return INT2FIX(can_link(who_ref, what_ref));
}

static VALUE do_payfor(VALUE self, VALUE who, VALUE cost)
{
    (void) self;
    dbref who_ref = FIX2INT(who);
    int cost_of = FIX2INT(cost);
    return INT2FIX(payfor(who_ref, cost_of));
}

static VALUE do_ok_name(VALUE self, VALUE name)
{
    (void) self;
    const char* name_s = 0;
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    return INT2FIX(ok_name(name_s));
}

static VALUE do_ok_player_name(VALUE self, VALUE name)
{
    (void) self;
    const char* name_s = 0;
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    return INT2FIX(ok_player_name(name_s));
}

void Init_predicates()
{   
    predicates_class = rb_define_class_under(tinymud_module, "Predicates", rb_cObject);
    rb_define_method(predicates_class, "can_link_to", do_can_link_to, 2);
    rb_define_method(predicates_class, "could_doit", do_could_doit, 2);
    rb_define_method(predicates_class, "can_doit", do_can_doit, 3);
    rb_define_method(predicates_class, "can_see", do_can_see, 3);
    rb_define_method(predicates_class, "controls", do_controls, 2);
    rb_define_method(predicates_class, "can_link", do_can_link, 2);
    rb_define_method(predicates_class, "payfor", do_payfor, 2);
    rb_define_method(predicates_class, "ok_name", do_ok_name, 1);
    rb_define_method(predicates_class, "ok_player_name", do_ok_player_name, 1);
}
