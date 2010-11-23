#include "ruby.h"

VALUE c;

static VALUE hello(VALUE self)
{
  return INT2FIX(100);
}

// This is pretending to be the "c" stub
static VALUE stub(VALUE self)
{
  ID method = rb_intern("hello");
  rb_funcall(c, method, 0);
  return Qnil;
}

void Init_jam() {
    c = rb_define_class("Jam", rb_cObject);
	rb_define_singleton_method(c, "hello", hello, 0);
    rb_define_method(c, "stub", stub, 0);
}
