/* Prototypes for externs not defined elsewhere */
#include "db.h"

/* From player.c */
extern dbref lookup_player(const char *name);
extern void do_password(dbref player, const char *old, const char *newobj);
