#include "ruby.h"
#include "db.h"
#include "interface.h"
#include "tinymud.h"

VALUE tinymud_module;

/******************************************************************************/
/* These are in the TinyMud module so I can mock them from ruby, see below    */
/******************************************************************************/

static VALUE do_notify(VALUE self, VALUE player, VALUE message)
{
  (void) self;
  (void) player;
  (void) message;
  return Qnil;
}

static VALUE do_emergency_shutdown(VALUE self)
{
  (void) self;
  return Qnil;
}

/******************************************************************************/
/* These are part of interface.h, they call tinymud network code which for now*/
/* I want to leave out of the tests                                           */
/******************************************************************************/

void notify(dbref player_ref, const char *msg)
{
  ID method = rb_intern("do_notify");
  VALUE player = INT2FIX(player_ref);
  VALUE message = rb_str_new2(msg);
  rb_funcall(tinymud_module, method, player, message);
}

/******************************************************************************/

void emergency_shutdown(void)
{
  ID method = rb_intern("do_emergency_shutdown");
  rb_funcall(tinymud_module, method, 0);
}

void Init_tinymud()
{
	tinymud_module = rb_define_module("TinyMud");
    rb_define_method(tinymud_module, "do_notify", do_notify, 2);
    rb_define_method(tinymud_module, "do_emergency_shutdown", do_emergency_shutdown, 0);
    
    Init_db();
    Init_player();
    Init_predicates();
}
