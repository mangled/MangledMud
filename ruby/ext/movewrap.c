#include "ruby.h"
#include "db.h"
#include "move.h"
#include "tinymud.h"

static VALUE move_class;

static VALUE do_moveto(VALUE self, VALUE what, VALUE where)
{
    (void) self;
    dbref what_ref = FIX2INT(what);
    dbref where_ref = FIX2INT(where);
    moveto(what_ref, where_ref);
    return Qnil;
}

static VALUE do_enter_room(VALUE self, VALUE player, VALUE loc)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref loc_ref = FIX2INT(loc);
    enter_room(player_ref, loc_ref);
    return Qnil;
}

static VALUE do_send_home(VALUE self, VALUE thing)
{
    (void) self;
    send_home(FIX2INT(thing));
    return Qnil;
}

static VALUE do_can_move(VALUE self, VALUE player, VALUE direction)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* direction_s = 0;
    if (direction != Qnil) {
        direction_s = STR2CSTR(direction);
    }
    return INT2FIX(can_move(player_ref, direction_s));
}

static VALUE do_do_move(VALUE self, VALUE player, VALUE direction)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* direction_s = 0;
    if (direction != Qnil) {
        direction_s = STR2CSTR(direction);
    }
    do_move(player_ref, direction_s);
    return Qnil;
}

static VALUE do_do_get(VALUE self, VALUE player, VALUE what)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* what_s = 0;
    if (what != Qnil) {
        what_s = STR2CSTR(what);
    }
    do_get(player_ref, what_s);
    return Qnil;
}

static VALUE do_do_drop(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = 0;
    if (name != Qnil) {
        name_s = STR2CSTR(name);
    }
    do_drop(player_ref, name_s);
    return Qnil;
}

void Init_move()
{   
    move_class = rb_define_class_under(tinymud_module, "Move", rb_cObject);
    rb_define_method(move_class, "moveto", do_moveto, 2);
    rb_define_method(move_class, "enter_room", do_enter_room, 2);
    rb_define_method(move_class, "send_home", do_send_home, 1);
    rb_define_method(move_class, "can_move", do_can_move, 2);
    rb_define_method(move_class, "do_move", do_do_move, 2);
    rb_define_method(move_class, "do_get", do_do_get, 2);
    rb_define_method(move_class, "do_drop", do_do_drop, 2);
}
