#include "ruby.h"
#include "db.h"
#include "stringutil.h"
#include "tinymud.h"

static VALUE stringutil_class;

static VALUE do_string_compare(VALUE self, VALUE s1, VALUE s2)
{
    (void) self;
    char* s1_s = strdup("\0");
    if (s1 != Qnil) {
        s1_s = StringValuePtr(s1);
    }
    char* s2_s = strdup("\0");
    if (s2 != Qnil) {
        s2_s = StringValuePtr(s2);
    }
    return INT2FIX(string_compare(s1_s, s2_s));
}

static VALUE do_string_prefix(VALUE self, VALUE string, VALUE prefix)
{
    (void) self;
    char* string_s = strdup("\0");
    if (string != Qnil) {
        string_s = StringValuePtr(string);
    }
    char* prefix_s = strdup("\0");
    if (prefix != Qnil) {
        prefix_s = StringValuePtr(prefix);
    }
    return INT2FIX(string_prefix(string_s, prefix_s));
}

static VALUE do_string_match(VALUE self, VALUE src, VALUE sub)
{
    (void) self;
    char* src_s = strdup("\0");
    if (src != Qnil) {
        src_s = StringValuePtr(src);
    }
    char* sub_s = strdup("\0");
    if (sub != Qnil) {
        sub_s = StringValuePtr(sub);
    }
    return INT2FIX(string_match(src_s, sub_s));
}

void Init_stringutil()
{   
    stringutil_class = rb_define_class_under(tinymud_module, "StringUtil", rb_cObject);
    rb_define_method(stringutil_class, "string_compare", do_string_compare, 2);
    rb_define_method(stringutil_class, "string_prefix", do_string_prefix, 2);
    rb_define_method(stringutil_class, "string_match", do_string_match, 2);
}
