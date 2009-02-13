#include "copyright.h"

/* Prototypes for externs not defined elsewhere */
#include "db.h"

/* From create.c */
extern void do_open(dbref player, const char *direction, const char *linkto);
extern void do_link(dbref player, const char *name, const char *room_name);
extern void do_dig(dbref player, const char *name);
extern void do_create(dbref player, char *name, int cost);

/* From game.c */
extern void do_dump(dbref player);
extern void do_shutdown(dbref player);

/* From help.c */
extern void spit_file(dbref player, const char *filename);
extern void do_help(dbref player);
extern void do_news(dbref player);

/* From look.c */
extern void look_room(dbref player, dbref room);
extern void do_look_around(dbref player);
extern void do_look_at(dbref player, const char *name);
extern void do_examine(dbref player, const char *name);
extern void do_inventory(dbref player);
extern void do_find(dbref player, const char *name);

/* From move.c */
extern void moveto(dbref what, dbref where);
extern void enter_room(dbref player, dbref loc);
extern void send_home(dbref thing);
extern int can_move(dbref player, const char *direction);
extern void do_move(dbref player, const char *direction);
extern void do_get(dbref player, const char *what);
extern void do_drop(dbref player, const char *name);

/* From player.c */
extern dbref lookup_player(const char *name);
extern void do_password(dbref player, const char *old, const char *newobj);

/* From predicates.h */
extern int can_link_to(dbref who, dbref where);
extern int could_doit(dbref player, dbref thing);
extern int can_doit(dbref player, dbref thing, const char *default_fail_msg);
extern int can_see(dbref player, dbref thing, int can_see_location);
extern int controls(dbref who, dbref what);
extern int payfor(dbref who, int cost);

/* From rob.c */
extern void do_kill(dbref player, const char *what, int cost);
extern void do_give(dbref player, char *recipient, int amount);
extern void do_rob(dbref player, const char *what);

/* From set.c */
extern void do_name(dbref player, const char *name, char *newname);
extern void do_describe(dbref player, const char *name, const char *description);
extern void do_fail(dbref player, const char *name, const char *message);
extern void do_success(dbref player, const char *name, const char *message);
extern void do_osuccess(dbref player, const char *name, const char *message);
extern void do_ofail(dbref player, const char *name, const char *message);
extern void do_lock(dbref player, const char *name, const char *keyname);
extern void do_unlock(dbref player, const char *name);
extern void do_unlink(dbref player, const char *name);
extern void do_chown(dbref player, const char *name, const char *newobj);
extern void do_set(dbref player, const char *name, const char *flag);

/* From speech.c */
extern void do_wall(dbref player, const char *arg1, const char *arg2);
extern void do_gripe(dbref player, const char *arg1, const char *arg2);
extern void do_say(dbref player, const char *arg1, const char *arg2);
extern void do_page(dbref player, const char *arg1);
extern void notify_except(dbref first, dbref exception, const char *msg);

/* From stringutil.c */
extern int string_compare(const char *s1, const char *s2);
extern int string_prefix(const char *string, const char *prefix);
extern const char *string_match(const char *src, const char *sub);

/* From utils.c */
extern int member(dbref thing, dbref list);
extern dbref remove_first(dbref first, dbref what);
extern const char *getname(dbref thing);

/* From wiz.c */
extern void do_teleport(dbref player, const char *arg1, const char *arg2);
extern void do_force(dbref player, const char *what, char *command);
extern void do_stats(dbref player, const char *name);
