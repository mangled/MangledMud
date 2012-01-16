extern dbref lookup_player(const char *name);
extern dbref connect_player(const char *name, const char *password);
extern dbref create_player(const char *name, const char *password);
extern void do_password(dbref player, const char *old, const char *newobj);
