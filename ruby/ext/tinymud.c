#include "ruby.h"
#include "db.h"
#include "interface.h"
#include "tinymud.h"

VALUE tinymud_module;
VALUE interface_class;

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

static VALUE do_process_command(VALUE self, VALUE player, VALUE command)
{
  (void) self;
  (void) player;
  (void) command;
  return INT2FIX(1);
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
  rb_funcall(interface_class, method, 2, player, message);
}

/******************************************************************************/

void emergency_shutdown(void)
{
  ID method = rb_intern("do_emergency_shutdown");
  rb_funcall(interface_class, method, 0);
}

void Init_tinymud()
{
#ifdef BUILD_ORIGINAL
  tinymud_module = rb_define_module("TinyMud");
  interface_class = rb_define_class_under(tinymud_module, "Interface", rb_cObject);
  rb_define_module_function(interface_class, "do_notify", do_notify, 2);
  rb_define_module_function(interface_class, "do_emergency_shutdown", do_emergency_shutdown, 0);
  rb_define_module_function(interface_class, "do_process_command", do_process_command, 2);
  
  Init_db();
  Init_player();
  Init_predicates();
  Init_match();
  Init_utils();
  Init_speech();
  Init_move();
  Init_look();
  Init_create();
  Init_set();
  Init_rob();
  Init_wiz();
  Init_stringutil();
  Init_game();
  Init_help();

#else // Converted build => Only unconverted code is left here
  tinymud_module = rb_define_module("TinyMud");
  interface_class = rb_define_class_under(tinymud_module, "Interface", rb_cObject);
  rb_define_module_function(interface_class, "do_notify", do_notify, 2);
  rb_define_module_function(interface_class, "do_emergency_shutdown", do_emergency_shutdown, 0);
  rb_define_module_function(interface_class, "do_process_command", do_process_command, 2);
  
  // Remove each line, replace with a pure ruby implementation (empty at first)
  // run $ rake test_converted (whilst building up the pure ruby version)
  // db maybe a problem as it uses static's, I'm sure there will be a simple fix
  // for this. Maybe tackle it last...
  // The main aim is to keep the tests passing (for both build types)
  Init_look();
  Init_create();
  Init_stringutil();
  Init_game();
#endif
}
