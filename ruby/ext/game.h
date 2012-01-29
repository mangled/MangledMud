/* Exported by tinymud.h - To allow stubbing */
extern VALUE interface_class;

extern void do_dump(dbref player);
extern void dump_database_to_file(const char* filename);
extern void set_dumpfile_name(const char* filename);
extern void do_shutdown(dbref player);
