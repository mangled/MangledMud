#include "ruby.h"
#include "db.h"
#include "player.h"
#include "tinymud.h"

static VALUE player_class;

static VALUE do_lookup_player(VALUE self, VALUE player_name)
{
    (void) self;
    const char* name = STR2CSTR(player_name);
    dbref ref = lookup_player(name);
    return INT2FIX(ref);
}

static VALUE do_connect_player(VALUE self, VALUE player_name, VALUE password)
{
    (void) self;
    const char* name = STR2CSTR(player_name);
    const char* pwd = STR2CSTR(password);
    dbref ref = connect_player(name, pwd);
    return INT2FIX(ref);
}

static VALUE do_create_player(VALUE self, VALUE player_name, VALUE password)
{
    (void) self;
    const char* name = STR2CSTR(player_name);
    const char* pwd = STR2CSTR(password);
    dbref ref = create_player(name, pwd);
    return INT2FIX(ref);
}

static VALUE do_do_password(VALUE self, VALUE player_ref, VALUE old_pwd, VALUE new_pwd)
{
    (void) self;
    dbref player = FIX2INT(player_ref);
    const char* oldp = STR2CSTR(old_pwd);
    const char* newp = STR2CSTR(new_pwd);
    do_password(player, oldp, newp);
    return Qnil;
}

void Init_player()
{	
    player_class = rb_define_class_under(tinymud_module, "Player", rb_cObject);
    rb_define_method(player_class, "lookup_player", do_lookup_player, 1);
    rb_define_method(player_class, "connect_player", do_connect_player, 2);
    rb_define_method(player_class, "create_player", do_create_player, 2);
    rb_define_method(player_class, "change_password", do_do_password, 3);
}
