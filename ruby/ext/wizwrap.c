#include "ruby.h"
#include "db.h"
#include "wiz.h"
#include "tinymud.h"

static VALUE wiz_class;

static VALUE do_do_teleport(VALUE self, VALUE player, VALUE arg1, VALUE arg2)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* arg1_s = strdup("\0");
    if (arg1 != Qnil) {
        arg1_s = StringValuePtr(arg1);
    }
    char* arg2_s = strdup("\0");
    if (arg2 != Qnil) {
        arg2_s = StringValuePtr(arg2);
    }
    do_teleport(player_ref, arg1_s, arg2_s);
    return Qnil;
}

static VALUE do_do_force(VALUE self, VALUE player, VALUE what, VALUE command)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* what_s = strdup("\0");
    if (what != Qnil) {
        what_s = StringValuePtr(what);
    }
    char* command_s = strdup("\0");
    if (command != Qnil) {
        command_s = StringValuePtr(command);
    }
    do_force(player_ref, what_s, command_s);
    return Qnil;
}

static VALUE do_do_stats(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_stats(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_toad(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_toad(player_ref, name_s);
    return Qnil;
}

void Init_wiz()
{   
    wiz_class = rb_define_class_under(tinymud_module, "Wiz", rb_cObject);
    rb_define_method(wiz_class, "do_teleport", do_do_teleport, 3);
    rb_define_method(wiz_class, "do_force", do_do_force, 3);
    rb_define_method(wiz_class, "do_stats", do_do_stats, 2);
    rb_define_method(wiz_class, "do_toad", do_do_toad, 2);
}
