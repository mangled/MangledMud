/* Exported by tinymud.h - To allow stubbing */
extern VALUE interface_class;

/* exported to allow stubbing of rand */
extern VALUE game_class;

extern void do_dump(dbref player);
extern void dump_database_to_file(const char* filename);
extern void set_dumpfile_name(const char* filename);
extern void do_shutdown(dbref player);
