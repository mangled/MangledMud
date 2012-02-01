#include "ruby.h"
#include "db.h"
#include "help.h"
#include "tinymud.h"

static VALUE help_class;

static VALUE do_do_help(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);    
    do_help(player_ref);
    return Qnil;
}

static VALUE do_do_news(VALUE self, VALUE player)
{
    (void) self;
    dbref player_ref = FIX2INT(player);    
    do_news(player_ref);
    return Qnil;
}

static VALUE do_initialize(VALUE self, VALUE db)
{
	(void) self;
	(void) db;
}

void Init_help()
{   
    help_class = rb_define_class_under(tinymud_module, "Help", rb_cObject);
    rb_define_method(help_class, "do_help", do_do_help, 1);
    rb_define_method(help_class, "do_news", do_do_news, 1);
	rb_define_method(help_class, "initialize", do_initialize, 1);
}
