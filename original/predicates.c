#include "copyright.h"

/* Predicates for testing various conditions */

#include <ctype.h>

#include "db.h"
#include "interface.h"
#include "config.h"
#include "externs.h"

int can_link_to(dbref who, dbref where)
{
    return(where >= 0
	   && where < db_top
	   && Typeof(where) == TYPE_ROOM
	   && (controls(who, where) || (db[where].flags & LINK_OK)));
}

int could_doit(dbref player, dbref thing)
{
    dbref key;
    int status;

    if(Typeof(thing) != TYPE_ROOM && db[thing].location == NOTHING) return 0;
    if((key = db[thing].key) == NOTHING) return 1;
    status = (player == key || member(key, db[player].contents));
    return((db[thing].flags & ANTILOCK) ? !status : status);
}

int can_doit(dbref player, dbref thing, const char *default_fail_msg)
{
    dbref loc;
    char buf[BUFFER_LEN];

    if((loc = getloc(player)) == NOTHING) return 0;

    if(!could_doit(player, thing)) {
	/* can't do it */
	if(db[thing].fail_message) {
	    notify(player, db[thing].fail_message);
	} else if(default_fail_msg) {
	    notify(player, default_fail_msg);
	}
	
	if(db[thing].ofail) {
	    sprintf(buf, "%s %s", db[player].name, db[thing].ofail);
	    notify_except(db[loc].contents, player, buf);
	}

	return 0;
    } else {
	/* can do it */
	if(db[thing].succ_message) {
	    notify(player, db[thing].succ_message);
	}

	if(db[thing].osuccess) {
	    sprintf(buf, "%s %s", db[player].name, db[thing].osuccess);
	    notify_except(db[loc].contents, player, buf);
	}

	return 1;
    }
}

int can_see(dbref player, dbref thing, int can_see_loc)
{
    if(player == thing || Typeof(thing) == TYPE_EXIT) {
	return 0;
    } else if(can_see_loc) {
	return(!Dark(thing) || controls(player, thing));
    } else {
	/* can't see loc */
	return(controls(player, thing));
    }
}

int controls(dbref who, dbref what)
{
    /* Wizard controls everything */
    /* owners control their stuff */
    return(what >= 0
	   && what < db_top
	   && (Wizard(who)
	       || who == db[what].owner));
}

int can_link(dbref who, dbref what)
{
    return((Typeof(what) == TYPE_EXIT && db[what].location == NOTHING)
	   || controls(who, what));
}

int payfor(dbref who, int cost)
{
    if(Wizard(who)) {
	return 1;
    } else if(db[who].pennies >= cost) {
	db[who].pennies -= cost;
	return 1;
    } else {
	return 0;
    }
}

int ok_name(const char *name)
{
    return (name
	    && *name
	    && *name != LOOKUP_TOKEN
	    && *name != NUMBER_TOKEN
	    && string_compare(name, "me")
	    && string_compare(name, "home")
	    && string_compare(name, "here"));
}

int ok_player_name(const char *name)
{
    const char *scan;

    if(!ok_name(name)) return 0;

    for(scan = name; *scan; scan++) {
	if(!isgraph(*scan)) {
	    return 0;
	}
    }

    /* lookup name to avoid conflicts */
    return (lookup_player(name) == NOTHING);
}
