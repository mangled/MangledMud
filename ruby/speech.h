extern const char *reconstruct_message(const char *arg1, const char *arg2);
extern void do_wall(dbref player, const char *arg1, const char *arg2);
extern void do_gripe(dbref player, const char *arg1, const char *arg2);
extern void do_say(dbref player, const char *arg1, const char *arg2);
extern void do_pose(dbref player, const char *arg1, const char *arg2);
extern void do_page(dbref player, const char *arg1);
extern void notify_except(dbref first, dbref exception, const char *msg);
