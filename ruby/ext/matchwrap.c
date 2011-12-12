#include "ruby.h"
#include "db.h"
#include "match.h"
#include "tinymud.h"

static VALUE match_class;

static VALUE do_init_match(VALUE self, VALUE player, VALUE name, VALUE type)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    int type_is = FIX2INT(type);
    const char* name_s = 0;
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    init_match(player_ref, name_s, type_is);
    return Qnil;
}

static VALUE do_init_match_check_keys(VALUE self, VALUE player, VALUE name, VALUE type)
{
    (void) self;
    dbref player_ref = FIX2INT(player);
    dbref type_is = FIX2INT(type);
    const char* name_s = 0;
    if (name != Qnil) {
        name_s = StringValuePtr(name);
    }
    init_match_check_keys(player_ref, name_s, type_is);
    return Qnil;
}

static VALUE do_match_player(VALUE self)
{
    (void) self;
    match_player();
    return Qnil;
}

static VALUE do_match_absolute(VALUE self)
{
    (void) self;
    match_absolute();
    return Qnil;
}

static VALUE do_match_me(VALUE self)
{
    (void) self;
    match_me();
    return Qnil;
}

static VALUE do_match_here(VALUE self)
{
    (void) self;
    match_here();
    return Qnil;
}

static VALUE do_match_possession(VALUE self)
{
    (void) self;
    match_possession();
    return Qnil;
}

static VALUE do_match_neighbor(VALUE self)
{
    (void) self;
    match_neighbor();
    return Qnil;
}

static VALUE do_match_exit(VALUE self)
{
    (void) self;
    match_exit();
    return Qnil;    
}

static VALUE do_match_everything(VALUE self)
{
    (void) self;
    match_everything();
    return Qnil;    
}

static VALUE do_match_result(VALUE self)
{
    (void) self;
    return INT2FIX(match_result());
}

static VALUE do_last_match_result(VALUE self)
{
    (void) self;
    return INT2FIX(last_match_result());
}

static VALUE do_noisy_match_result(VALUE self)
{
    (void) self;
    return INT2FIX(noisy_match_result());
}

void Init_match()
{   
    match_class = rb_define_class_under(tinymud_module, "Match", rb_cObject);
    rb_define_method(match_class, "init_match", do_init_match, 3);
    rb_define_method(match_class, "init_match_check_keys", do_init_match_check_keys, 3);
    rb_define_method(match_class, "match_player", do_match_player, 0);
    rb_define_method(match_class, "match_absolute", do_match_absolute, 0);
    rb_define_method(match_class, "match_me", do_match_me, 0);
    rb_define_method(match_class, "match_here", do_match_here, 0);
    rb_define_method(match_class, "match_possession", do_match_possession, 0);
    rb_define_method(match_class, "match_neighbor", do_match_neighbor, 0);
    rb_define_method(match_class, "match_exit", do_match_exit, 0);
    rb_define_method(match_class, "match_everything", do_match_everything, 0);

    rb_define_method(match_class, "match_result", do_match_result, 0);
    rb_define_method(match_class, "last_match_result", do_last_match_result, 0);
    rb_define_method(match_class, "noisy_match_result", do_noisy_match_result, 0);
}
