extern void moveto(dbref what, dbref where);
extern void enter_room(dbref player, dbref loc);
extern void send_home(dbref thing);
extern int can_move(dbref player, const char *direction);
extern void do_move(dbref player, const char *direction);
extern void do_get(dbref player, const char *what);
extern void do_drop(dbref player, const char *name);
