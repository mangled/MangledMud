#include "copyright.h"

/* Commands which involve speaking */
#include <string.h>

#include "db.h"
#include "interface.h"
#include "match.h"
#include "config.h"
#include "speech.h"
#include "player.h"
#include "utils.h"
#include "predicates.h"

/* this function is a kludge for regenerating messages split by '=' */
const char *reconstruct_message(const char *arg1, const char *arg2)
{
    static char buf[BUFFER_LEN];

    if(arg2 && *arg2) {
	strcpy(buf, arg1);
	strcat(buf, " = ");
	strcat(buf, arg2);
	return buf;
    } else {
	return arg1;
    }
}

void do_say(dbref player, const char *arg1, const char *arg2)
{
    dbref loc;
    const char *message;
    char buf[BUFFER_LEN];

    if((loc = getloc(player)) == NOTHING) return;

    message = reconstruct_message(arg1, arg2);

    /* notify everybody */
    sprintf(buf, "You say \"%s\"", message);
    notify(player, buf);
    sprintf(buf, "%s says \"%s\"", db[player].name, message);
    notify_except(db[loc].contents, player, buf);
}

void do_pose(dbref player, const char *arg1, const char *arg2)
{
    dbref loc;
    const char *message;
    char buf[BUFFER_LEN];

    if((loc = getloc(player)) == NOTHING) return;

    message = reconstruct_message(arg1, arg2);

    /* notify everybody */
    sprintf(buf, "%s %s", db[player].name, message);
    notify_except(db[loc].contents, NOTHING, buf);
}

void do_wall(dbref player, const char *arg1, const char *arg2)
{
    dbref i;
    const char *message;
    char buf[512];

    message = reconstruct_message(arg1, arg2);
    if(Wizard(player)) {
	fprintf(stderr, "WALL from %s(%d): %s\n",
		db[player].name, player, message);
	sprintf(buf, "%s shouts \"%s\"", db[player].name, message);
	for(i = 0; i < db_top; i++) {
	    if(Typeof(i) == TYPE_PLAYER) {
		notify(i, buf);
	    }
	}
    } else {
	notify(player, "But what do you want to do with the wall?");
    }
}

void do_gripe(dbref player, const char *arg1, const char *arg2)
{
    dbref loc;
    const char *message;

    loc = db[player].location;
    message = reconstruct_message(arg1, arg2);
    fprintf(stderr, "GRIPE from %s(%d) in %s(%d): %s\n",
	    db[player].name, player,
	    getname(loc), loc,
	    message);
    fflush(stderr);

    notify(player, "Your complaint has been duly noted.");
}

/* doesn't really belong here, but I couldn't figure out where else */
void do_page(dbref player, const char *arg1)
{
    char buf[BUFFER_LEN];
    dbref target;

    if(!payfor(player, LOOKUP_COST)) {
	notify(player, "You don't have enough pennies.");
    } else if((target = lookup_player(arg1)) == NOTHING) {
	notify(player, "I don't recognize that name.");
    } else {
	sprintf(buf, "You sense that %s is looking for you in %s.",
		db[player].name, db[db[player].location].name);
	notify(target, buf);
	notify(player, "Your message has been sent.");
    }
}

void notify_except(dbref first, dbref exception, const char *msg)
{
    DOLIST (first, first) {
	if ((db[first].flags & TYPE_MASK) == TYPE_PLAYER
	    && first != exception) {
	    notify (first, msg);
	}
    }
}
