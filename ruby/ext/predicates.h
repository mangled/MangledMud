extern int can_link_to(dbref who, dbref where);
extern int could_doit(dbref player, dbref thing);
extern int can_doit(dbref player, dbref thing, const char *default_fail_msg);
extern int can_see(dbref player, dbref thing, int can_see_location);
extern int controls(dbref who, dbref what);
extern int payfor(dbref who, int cost);
extern int can_link(dbref who, dbref what);
extern int ok_name(const char *name);
extern int ok_player_name(const char *name);
