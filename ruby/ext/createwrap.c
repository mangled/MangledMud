#include "ruby.h"
#include "db.h"
#include "create.h"
#include "tinymud.h"

static VALUE create_class;

static VALUE do_do_open(VALUE self, VALUE player, VALUE direction, VALUE linkto)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* direction_s = strdup("\0");
    if (direction != Qnil) {
        direction_s = STR2CSTR(direction);
    }
    char* linkto_s = strdup("\0");
    if (linkto != Qnil) {
        linkto_s = STR2CSTR(linkto);
    }
    do_open(player_ref, direction_s, linkto_s);
    return Qnil;
}

static VALUE do_do_link(VALUE self, VALUE player, VALUE name, VALUE room_name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = STR2CSTR(name);
    }
    char* room_name_s = strdup("\0");
    if (room_name != Qnil) {
        room_name_s = STR2CSTR(room_name);
    }
    do_link(player_ref, name_s, room_name_s);
    return Qnil;
}

static VALUE do_do_dig(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = STR2CSTR(name);
    }
    do_dig(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_create(VALUE self, VALUE player, VALUE name, VALUE cost)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = STR2CSTR(name);
    }
    int cost_val = FIX2INT(cost);
    do_create(player_ref, name_s, cost_val);
    return Qnil;
}

void Init_create()
{   
    create_class = rb_define_class_under(tinymud_module, "Create", rb_cObject);
    rb_define_method(create_class, "do_open", do_do_open, 3);
    rb_define_method(create_class, "do_link", do_do_link, 3);
    rb_define_method(create_class, "do_dig", do_do_dig, 2);
    rb_define_method(create_class, "do_create", do_do_create, 3);
}
