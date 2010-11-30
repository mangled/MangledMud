#include "ruby.h"
#include "db.h"

static VALUE tinymud_module;
static VALUE db_class;
static VALUE db_record;

/* Database Methods */

static VALUE db_new_object(VALUE self)
{
	(void) self;
	return INT2FIX(new_object());
}

static VALUE db_free_content(VALUE self)
{
	(void) self;
	db_free();
	return Qnil;
}

static VALUE db_length(VALUE self)
{
	(void) self;
	return INT2FIX(db_top);
}

static void free_record_elements(struct object* record)
{
    if (record->name) free((void*) record->name);
    if (record->description) free((void*) record->description);
    if (record->succ_message) free((void*) record->succ_message);
    if (record->fail_message) free((void*) record->fail_message);
    if (record->ofail) free((void*) record->ofail);
    if (record->osuccess) free((void*) record->osuccess);
	if (record->password) free((void*) record->password);
}

static void copy_record_elements(const struct object* src, struct object* dst)
{
	if (src->name) {
		dst->name = strdup(src->name);
	}
    if (src->description) {
		dst->description = strdup(src->description);
	}
    if (src->succ_message) {
		dst->succ_message = strdup(src->succ_message);
	}
    if (src->fail_message) {
		dst->fail_message = strdup(src->fail_message);
	}
    if (src->ofail) {
		dst->ofail = strdup(src->ofail);
	}
    if (src->osuccess) {
		dst->osuccess = strdup(src->osuccess);
	}
	if (src->password) {
		dst->password = strdup(src->password);
	}
}

static void record_free(struct object* record)
{
	free_record_elements(record);
	free(record);
}

static VALUE get_record(VALUE self, VALUE at)
{
	(void) self;
	if (db == 0) { rb_raise(rb_eRuntimeError, "db is empty!"); }
	dbref where = FIX2INT(at);
	if (where < 0 || where >= db_top) { rb_raise(rb_eRuntimeError, "invalid at"); }

	struct object* record = &(db[where]);
	struct object* new_record = malloc(sizeof(struct object));
	memcpy(new_record, record, sizeof(struct object));

	copy_record_elements(record, new_record);

	return Data_Wrap_Struct(db_record, 0, record_free, new_record);
}

static VALUE db_put_record(VALUE self, VALUE at, VALUE record)
{
	(void) self;
	if (db == 0) { rb_raise(rb_eRuntimeError, "db is empty!"); }
	dbref where = FIX2INT(at);
	if (where < 0 || where >= db_top) { rb_raise(rb_eRuntimeError, "invalid at"); }

	struct object* source;
	Data_Get_Struct(record, struct object, source);

	struct object* destination = &(db[where]);
	free_record_elements(destination);
	memcpy(destination, source, sizeof(struct object));
	copy_record_elements(source, destination);

	return Qnil;
}

// Note: This does read from file, but I'm not concerned as at some point
// this will be replaced by ruby code
static VALUE minimal(VALUE self) // Fixme: Almost the same as below (not DRY)
{
	(void) self;
	const char* filename = "minimal.db";
	FILE* file = fopen(filename, "r");
	if (file == 0) { rb_raise(rb_eRuntimeError, "failed opening file"); }
	db_read(file);
	fclose(file);
	return Qnil;
}

static VALUE db_read_from_file(VALUE self, VALUE db_name)
{
	(void) self;
	char* filename = STR2CSTR(db_name);
	FILE* file = fopen(filename, "r");
	if (file == 0) { rb_raise(rb_eRuntimeError, "failed opening file"); }
	db_read(file);
	fclose(file);
	return Qnil;
}

/* Database struct/"object"/record */

static VALUE record_name(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->name) {
		return rb_str_new2(record->name);
	} else {
		return Qnil;
	}
}

static VALUE record_name_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->name) { free((void*) record->name); }
	record->name = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_description(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->description) {
		return rb_str_new2(record->description);
	} else {
		return Qnil;
	}
}

static VALUE record_description_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->description) { free((void*) record->description); }
	record->description = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_location(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->location);
}

static VALUE record_location_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->location = FIX2INT(i);
	return Qnil;
}

static VALUE record_contents(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->contents);
}

static VALUE record_contents_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->contents = FIX2INT(i);
	return Qnil;
}

static VALUE record_exits(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->exits);
}

static VALUE record_exits_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->exits = FIX2INT(i);
	return Qnil;
}

static VALUE record_next(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->next);
}

static VALUE record_next_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->next = FIX2INT(i);
	return Qnil;
}

static VALUE record_key(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->key);
}

static VALUE record_key_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->key = FIX2INT(i);
	return Qnil;
}

static VALUE record_fail_message(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->fail_message) {
		return rb_str_new2(record->fail_message);
	} else {
		return Qnil;
	}
}

static VALUE record_fail_message_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->fail_message) { free((void*) record->fail_message); }
	record->fail_message = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_succ_message(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->succ_message) {
		return rb_str_new2(record->succ_message);
	} else {
		return Qnil;
	}
}

static VALUE record_succ_message_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->succ_message) { free((void*) record->succ_message); }
	record->succ_message = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_ofail(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->ofail) {
		return rb_str_new2(record->ofail);
	} else {
		return Qnil;
	}
}

static VALUE record_ofail_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->ofail) { free((void*) record->ofail); }
	record->ofail = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_osuccess(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->osuccess) {
		return rb_str_new2(record->osuccess);
	} else {
		return Qnil;
	}
}

static VALUE record_osuccess_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->osuccess) { free((void*) record->osuccess); }
	record->osuccess = strdup(STR2CSTR(s));
	return Qnil;
}

static VALUE record_owner(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->owner);
}

static VALUE record_owner_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->owner = FIX2INT(i);
	return Qnil;
}

static VALUE record_pennies(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->pennies);
}

static VALUE record_pennies_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->pennies = FIX2INT(i);
	return Qnil;
}

static VALUE record_type_s(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);

	int type  = (record->flags) & TYPE_MASK;
	char* description = 0;
	switch (type) {
		case TYPE_ROOM:
			description = strdup("TYPE_ROOM");
		break;
		case TYPE_THING:
			description = strdup("TYPE_THING");
		break;
		case TYPE_EXIT:
			description = strdup("TYPE_EXIT");
		break;
		case TYPE_PLAYER:
			description = strdup("TYPE_PLAYER");
		break;
		case NOTYPE:
			description = strdup("NOTYPE");
		break;
		default:
			description = strdup("Unknown!");
		break;
	}
	if (description != 0) {
		return rb_str_new2(description);
	} else {
		return Qnil;
	}
}

static VALUE record_desc_s(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);

	int type  = (record->flags);
	char* description = 0;
	if ((type & ANTILOCK) != 0) {
		description = strdup("ANTILOCK");
	} else if ((type & WIZARD) != 0) {
		description = strdup("WIZARD");
	} else if ((type & LINK_OK) != 0) {
		description = strdup("LINK_OK");
	} else if ((type & DARK) != 0) {
		description = strdup("DARK");
	} else if ((type & TEMPLE) != 0) {
		description = strdup("TEMPLE");
	} else if ((type & STICKY) != 0) {
		description = strdup("STICKY");
	}
	if (description != 0) {
		return rb_str_new2(description);
	} else {
		return Qnil;
	}
}

static VALUE record_flags(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record); 
	return INT2FIX(record->flags);
}

static VALUE record_flags_set(VALUE self, VALUE i)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	record->flags = FIX2INT(i);
	return Qnil;
}

static VALUE record_password(VALUE self)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->password) {
		return rb_str_new2(record->password);
	} else {
		return Qnil;
	}
}

static VALUE record_password_set(VALUE self, VALUE s)
{
	struct object* record;
	Data_Get_Struct(self, struct object, record);
	if (record->password) { free((void*) record->password); }
	record->password = strdup(STR2CSTR(s));
	return Qnil;
}


/* INIT */
void Init_db() {
	tinymud_module = rb_define_module("TinyMud");

	db_class = rb_define_class_under(tinymud_module, "Db", rb_cObject);
	rb_define_module_function(db_class, "Minimal", minimal, 0);
	rb_define_method(db_class, "add_new_record", db_new_object, 0);
	rb_define_method(db_class, "put", db_put_record, 2);
	rb_define_method(db_class, "get", get_record, 1);
	rb_define_method(db_class, "length", db_length, 0);
	rb_define_method(db_class, "read", db_read_from_file, 1);
	rb_define_method(db_class, "free", db_free_content, 0);

	db_record = rb_define_class_under(tinymud_module, "Record", rb_cObject);
	rb_define_method(db_record, "name", record_name, 0);
	rb_define_method(db_record, "name=", record_name_set, 1);
	rb_define_method(db_record, "description", record_description, 0);
	rb_define_method(db_record, "description=", record_description_set, 1);
	rb_define_method(db_record, "location", record_location, 0);
	rb_define_method(db_record, "location=", record_location_set, 1);
	rb_define_method(db_record, "contents", record_contents, 0);
	rb_define_method(db_record, "contents=", record_contents_set, 1);
	rb_define_method(db_record, "exits", record_exits, 0);
	rb_define_method(db_record, "exits=", record_exits_set, 1);
	rb_define_method(db_record, "next", record_next, 0);
	rb_define_method(db_record, "next=", record_next_set, 1);
	rb_define_method(db_record, "key", record_key, 0);
	rb_define_method(db_record, "key=", record_key_set, 1);
	rb_define_method(db_record, "fail", record_fail_message, 0);
	rb_define_method(db_record, "fail=", record_fail_message_set, 1);
	rb_define_method(db_record, "succ", record_succ_message, 0);
	rb_define_method(db_record, "succ=", record_succ_message_set, 1);
	rb_define_method(db_record, "ofail", record_ofail, 0);
	rb_define_method(db_record, "ofail=", record_ofail_set, 1);
	rb_define_method(db_record, "osucc", record_osuccess, 0);
	rb_define_method(db_record, "osucc=", record_osuccess_set, 1);
	rb_define_method(db_record, "owner", record_owner, 0);
	rb_define_method(db_record, "owner=", record_owner_set, 1);
	rb_define_method(db_record, "pennies", record_pennies, 0);
	rb_define_method(db_record, "pennies=", record_pennies_set, 1);
	rb_define_method(db_record, "type", record_type_s, 0);
	rb_define_method(db_record, "desc", record_desc_s, 0);
	rb_define_method(db_record, "flags", record_flags, 0);
	rb_define_method(db_record, "flags=", record_flags_set, 1);
	rb_define_method(db_record, "password", record_password, 0);
	rb_define_method(db_record, "password=", record_password_set, 1);
}

