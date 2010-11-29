#include "ruby.h"
#include "db.h"
#include "player.h"

static VALUE tinymud_module;
static VALUE player_class;

/******************************************************************************/
/* The following are "stubbed" out from interface.h/.c I they touch underlying*/
/* socket/networking stuff, for now I don't want this to get in the way      */
/******************************************************************************/

void notify(dbref player, const char *msg)
{
  ID method = rb_intern("do_notify");
  rb_funcall(player_class, method, player, msg);
}

void emergency_shutdown(void)
{
  ID method = rb_intern("do_emergency_shutdown");
  rb_funcall(player_class, method, 0);
}

/* These are defined in ruby and called from the above - To allow mocking in ruby */

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

static VALUE do_lookup_player(VALUE self, VALUE player_name)
{
    (void) self;
    const char* name = STR2CSTR(player_name);
    dbref ref = lookup_player(name);
    return INT2FIX(ref);
}

void Init_player()
{
	tinymud_module = rb_define_module("TinyMud");
    
    player_class = rb_define_class_under(tinymud_module, "Player", rb_cObject);
    rb_define_method(player_class, "lookup_player", do_lookup_player, 1);
    rb_define_singleton_method(player_class, "do_notify", do_notify, 2);
    rb_define_singleton_method(player_class, "do_emergency_shutdown", do_emergency_shutdown, 0);
}
