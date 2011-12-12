#include "ruby.h"
#include "db.h"
#include "set.h"
#include "tinymud.h"

static VALUE set_class;

static VALUE do_do_name(VALUE self, VALUE player, VALUE name, VALUE newname)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* newname_s = strdup("\0");
    if (newname != Qnil) {
        newname_s = StringValuePtr(newname);
    }
    do_name(player_ref, name_s, newname_s);
    return Qnil;
}

static VALUE do_do_describe(VALUE self, VALUE player, VALUE name, VALUE description)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* description_s = strdup("\0");
    if (description != Qnil) {
        description_s = StringValuePtr(description);
    }
    do_describe(player_ref, name_s, description_s);
    return Qnil;
}

static VALUE do_do_fail(VALUE self, VALUE player, VALUE name, VALUE message)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* message_s = strdup("\0");
    if (message != Qnil) {
        message_s = StringValuePtr(message);
    }
    do_fail(player_ref, name_s, message_s);
    return Qnil;
}

static VALUE do_do_success(VALUE self, VALUE player, VALUE name, VALUE message)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* message_s = strdup("\0");
    if (message != Qnil) {
        message_s = StringValuePtr(message);
    }
    do_success(player_ref, name_s, message_s);
    return Qnil;
}

static VALUE do_do_osuccess(VALUE self, VALUE player, VALUE name, VALUE message)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* message_s = strdup("\0");
    if (message != Qnil) {
        message_s = StringValuePtr(message);
    }
    do_osuccess(player_ref, name_s, message_s);
    return Qnil;
}

static VALUE do_do_ofail(VALUE self, VALUE player, VALUE name, VALUE message)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* message_s = strdup("\0");
    if (message != Qnil) {
        message_s = StringValuePtr(message);
    }
    do_ofail(player_ref, name_s, message_s);
    return Qnil;
}

static VALUE do_do_lock(VALUE self, VALUE player, VALUE name, VALUE keyname)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* keyname_s = strdup("\0");
    if (keyname != Qnil) {
        keyname_s = StringValuePtr(keyname);
    }
    do_lock(player_ref, name_s, keyname_s);
    return Qnil;
}

static VALUE do_do_unlock(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_unlock(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_unlink(VALUE self, VALUE player, VALUE name)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    do_unlink(player_ref, name_s);
    return Qnil;
}

static VALUE do_do_chown(VALUE self, VALUE player, VALUE name, VALUE newobj)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* newobj_s = strdup("\0");
    if (newobj != Qnil) {
        newobj_s = StringValuePtr(newobj);
    }
    do_chown(player_ref, name_s, newobj_s);
    return Qnil;
}

static VALUE do_do_set(VALUE self, VALUE player, VALUE name, VALUE flag)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    char* name_s = strdup("\0");
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    char* flag_s = strdup("\0");
    if (flag != Qnil) {
        flag_s = StringValuePtr(flag);
    }
    do_set(player_ref, name_s, flag_s);
    return Qnil;
}

void Init_set()
{   
    set_class = rb_define_class_under(tinymud_module, "Set", rb_cObject);
    rb_define_method(set_class, "do_name", do_do_name, 3);
    rb_define_method(set_class, "do_describe", do_do_describe, 3);
    rb_define_method(set_class, "do_fail", do_do_fail, 3);
    rb_define_method(set_class, "do_success", do_do_success, 3);
    rb_define_method(set_class, "do_osuccess", do_do_osuccess, 3);
    rb_define_method(set_class, "do_ofail", do_do_ofail, 3);
    rb_define_method(set_class, "do_lock", do_do_lock, 3);
    rb_define_method(set_class, "do_unlock", do_do_unlock, 2);
    rb_define_method(set_class, "do_unlink", do_do_unlink, 2);
    rb_define_method(set_class, "do_chown", do_do_chown, 3);
    rb_define_method(set_class, "do_set", do_do_set, 3);
}
