#include "ruby.h"
#include "db.h"
#include "speech.h"
#include "tinymud.h"

static VALUE speech_class;

void Init_speech()
{   
    speech_class = rb_define_class_under(tinymud_module, "Speech", rb_cObject);
}
