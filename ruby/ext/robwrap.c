#include "ruby.h"
#include "db.h"
#include "rob.h"
#include "tinymud.h"

static VALUE rob_class;

static VALUE do_do_rob(VALUE self, VALUE player, VALUE what)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* what_s = strdup("\0");
    if (what != Qnil) {
        what_s = STR2CSTR(what);
    }
    do_rob(player_ref, what_s);
    return Qnil;
}

static VALUE do_do_kill(VALUE self, VALUE player, VALUE what, VALUE cost)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* what_s = strdup("\0");
    if (what != Qnil) {
        what_s = STR2CSTR(what);
    }
    int cost_val = FIX2INT(cost);
    do_kill(player_ref, what_s, cost_val);
    return Qnil;
}

static VALUE do_do_give(VALUE self, VALUE player, VALUE recipient, VALUE amount)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* recipient_s = strdup("\0");
    if (recipient != Qnil) {
        recipient_s = STR2CSTR(recipient);
    }
    int amount_val = FIX2INT(amount);
    do_give(player_ref, recipient_s, amount_val);
    return Qnil;
}

void Init_rob()
{   
    rob_class = rb_define_class_under(tinymud_module, "Rob", rb_cObject);
    rb_define_method(rob_class, "do_rob", do_do_rob, 2);
    rb_define_method(rob_class, "do_kill", do_do_kill, 3);
    rb_define_method(rob_class, "do_give", do_do_give, 3);
}
