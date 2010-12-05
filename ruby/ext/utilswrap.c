#include "ruby.h"
#include "db.h"
#include "utils.h"
#include "tinymud.h"

static VALUE utils_class;

static VALUE do_remove_first(VALUE self, VALUE first, VALUE what)
{
    (void) self;
    dbref first_ref = FIX2INT(first);
    dbref what_ref = FIX2INT(what);
    return INT2FIX(remove_first(first_ref, what_ref));
}

static VALUE do_member(VALUE self, VALUE thing, VALUE list)
{
    (void) self;
    dbref thing_ref = FIX2INT(thing);
    dbref list_ref = FIX2INT(list);
    return INT2FIX(member(thing_ref, list_ref));
}

static VALUE do_reverse(VALUE self, VALUE list)
{
    (void) self;
    dbref list_ref = FIX2INT(list);
    return INT2FIX(reverse(list_ref));
}

static VALUE do_getname(VALUE self, VALUE loc)
{
    (void) self;
    dbref loc_ref = FIX2INT(loc);
    return rb_str_new2(getname(loc_ref));
}

void Init_utils()
{   
    utils_class = rb_define_class_under(tinymud_module, "Utils", rb_cObject);
    rb_define_method(utils_class, "remove_first", do_remove_first, 2);
    rb_define_method(utils_class, "member", do_member, 2);
    rb_define_method(utils_class, "reverse", do_reverse, 1);
    rb_define_method(utils_class, "getname", do_getname, 1);
}
