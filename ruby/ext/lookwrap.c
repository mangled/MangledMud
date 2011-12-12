#include "ruby.h"
#include "db.h"
#include "look.h"
#include "tinymud.h"

static VALUE look_class;

static VALUE do_look_room(VALUE self, VALUE player, VALUE room)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref room_ref = FIX2INT(room);
    look_room(player_ref, room_ref);
    return Qnil;
}

static VALUE do_do_look_around(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    do_look_around(player_ref);
    return Qnil;
}

static VALUE do_do_look_at(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_look_at(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_examine(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_examine(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_score(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    do_score(player_ref);
    return Qnil;
}

static VALUE do_do_inventory(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    do_inventory(player_ref);
    return Qnil;
}

static VALUE do_do_find(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_find(player_ref, name_s);
    return Qnil;
}

void Init_look()
{   
    look_class = rb_define_class_under(tinymud_module, "Look", rb_cObject);
    rb_define_method(look_class, "look_room", do_look_room, 2);
    rb_define_method(look_class, "do_look_around", do_do_look_around, 1);
    rb_define_method(look_class, "do_look_at", do_do_look_at, 2);
    rb_define_method(look_class, "do_examine", do_do_examine, 2);
    rb_define_method(look_class, "do_score", do_do_score, 1);
    rb_define_method(look_class, "do_inventory", do_do_inventory, 1);
    rb_define_method(look_class, "do_find", do_do_find, 2);
}
