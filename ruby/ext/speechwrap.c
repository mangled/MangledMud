#include "ruby.h"
#include "db.h"
#include "speech.h"
#include "tinymud.h"

static VALUE speech_class;

static VALUE do_reconstruct_message(VALUE self, VALUE arg1, VALUE arg2)
{
    (void) self;
    const char* arg1_s = 0;
    const char* arg2_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    if (arg2 != Qnil) {
        arg2_s = STR2CSTR(arg2);
    }
    return rb_str_new2(reconstruct_message(arg1_s, arg2_s));
}

static VALUE do_do_say(VALUE self, VALUE player, VALUE arg1, VALUE arg2)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    const char* arg1_s = 0;
    const char* arg2_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    if (arg2 != Qnil) {
        arg2_s = STR2CSTR(arg2);
    }
    do_say(player_ref, arg1_s, arg2_s);
    return Qnil;
}

static VALUE do_do_pose(VALUE self, VALUE player, VALUE arg1, VALUE arg2)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    const char* arg1_s = 0;
    const char* arg2_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    if (arg2 != Qnil) {
        arg2_s = STR2CSTR(arg2);
    }
    do_pose(player_ref, arg1_s, arg2_s);
    return Qnil;
}

static VALUE do_do_wall(VALUE self, VALUE player, VALUE arg1, VALUE arg2)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    const char* arg1_s = 0;
    const char* arg2_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    if (arg2 != Qnil) {
        arg2_s = STR2CSTR(arg2);
    }
    do_wall(player_ref, arg1_s, arg2_s);
    return Qnil;
}

static VALUE do_do_gripe(VALUE self, VALUE player, VALUE arg1, VALUE arg2)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    const char* arg1_s = 0;
    const char* arg2_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    if (arg2 != Qnil) {
        arg2_s = STR2CSTR(arg2);
    }
    do_gripe(player_ref, arg1_s, arg2_s);
    return Qnil;
}

static VALUE do_do_page(VALUE self, VALUE player, VALUE arg1)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    const char* arg1_s = 0;
    if (arg1 != Qnil) {
        arg1_s = STR2CSTR(arg1);
    }
    do_page(player_ref, arg1_s);
    return Qnil;
}

static VALUE do_notify_except(VALUE self, VALUE first, VALUE exception, VALUE msg)
{
    (void) self;
    dbref first_ref = FIX2INT(first);
    dbref exception_ref = FIX2INT(exception);
    const char* msg_s = 0;
    if (msg != Qnil) {
        msg_s = STR2CSTR(msg);
    }
    notify_except(first_ref, exception_ref, msg_s);
    return Qnil;
}

void Init_speech()
{   
    speech_class = rb_define_class_under(tinymud_module, "Speech", rb_cObject);
    rb_define_method(speech_class, "reconstruct_message", do_reconstruct_message, 2);
    rb_define_method(speech_class, "do_say", do_do_say, 3);
    rb_define_method(speech_class, "do_pose", do_do_pose, 3);
    rb_define_method(speech_class, "do_wall", do_do_wall, 3);
    rb_define_method(speech_class, "do_gripe", do_do_gripe, 3);
    rb_define_method(speech_class, "do_page", do_do_page, 2);
    rb_define_method(speech_class, "notify_except", do_notify_except, 3);
}
