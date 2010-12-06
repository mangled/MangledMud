#include "copyright.h"

/* commands which look at things */
#include <string.h>

#include "db.h"
#include "config.h"
#include "interface.h"
#include "match.h"
#include "predicates.h"
#include "utils.h"
#include "look.h"
#include "stringutil.h"

static void notify_name(dbref player, dbref thing)
{
    char buf[BUFFER_LEN];

    if(controls(player, thing)) {
	/* tell him the number */
	sprintf(buf, "%s(#%d)", getname(thing), thing);
	notify(player, buf);
    } else {
	/* just tell him the name */
	notify(player, getname(thing));
    }
}

static void look_contents(dbref player, dbref loc, const char *contents_name)
{
    dbref thing;
    dbref can_see_loc;

    /* check to see if he can see the location */
    can_see_loc = (!Dark(loc) || controls(player, loc));

    /* check to see if there is anything there */
    DOLIST(thing, db[loc].contents) {
	if(can_see(player, thing, can_see_loc)) {
	    /* something exists!  show him everything */
	    notify(player, contents_name);
	    DOLIST(thing, db[loc].contents) {
		if(can_see(player, thing, can_see_loc)) {
		    notify_name(player, thing);
		}
	    }
	    break;		/* we're done */
	}
    }
}

static void look_simple(dbref player, dbref thing)
{
    if(db[thing].description) {
	notify(player, db[thing].description);
    } else {
	notify(player, "You see nothing special.");
    }
}

void look_room(dbref player, dbref loc)
{
    char buf[BUFFER_LEN];

    /* tell him the name, and the number if he can link to it */
    if(can_link_to(player, loc)) {
	sprintf(buf, "%s (#%d)", getname(loc), loc);
	notify(player, buf);
    } else {
	notify(player, getname(loc));
    }

    /* tell him the description */
    if(db[loc].description) notify(player, db[loc].description);

    /* tell him the appropriate messages if he has the key */
    can_doit(player, loc, 0);

    /* tell him the contents */
    look_contents(player, loc, "Contents:");
}

void do_look_around(dbref player)
{
    dbref loc;

    if((loc = getloc(player)) == NOTHING) return;
    look_room(player, loc);
}

void do_look_at(dbref player, const char *name)
{
    dbref thing;

    if(*name == '\0') {
	if((thing = getloc(player)) != NOTHING) {
	    look_room(player, thing);
	}
    } else {
	/* look at a thing here */
	init_match(player, name, NOTYPE);
	match_exit();
	match_neighbor();
	match_possession();
	if(Wizard(player)) {
	    match_absolute();
	    match_player();
	}
	match_here();
	match_me();

	if((thing = noisy_match_result()) != NOTHING) {
	    switch(Typeof(thing)) {
	      case TYPE_ROOM:
		look_room(player, thing);
		break;
	      case TYPE_PLAYER:
		look_simple(player, thing);
		look_contents(player, thing, "Carrying:");
		break;
	      default:
		look_simple(player, thing);
		break;
	    }
	}
    }
}

static const char *flag_description(dbref thing)
{
    static char buf[BUFFER_LEN];

    strcpy(buf, "Type: ");
    switch(Typeof(thing)) {
      case TYPE_ROOM:
	strcat(buf, "Room");
	break;
      case TYPE_EXIT:
	strcat(buf, "Exit");
	break;
      case TYPE_THING:
	strcat(buf, "Thing");
	break;
      case TYPE_PLAYER:
	strcat(buf, "Player");
	break;
      default:
	strcat(buf, "***UNKNOWN TYPE***");
	break;
    }

    if(db[thing].flags & ~TYPE_MASK) {
	/* print flags */
	strcat(buf, " Flags:");
	if(db[thing].flags & WIZARD) strcat(buf, " WIZARD");
	if(db[thing].flags & STICKY) strcat(buf, " STICKY");
	if(db[thing].flags & DARK) strcat(buf, " DARK");
	if(db[thing].flags & LINK_OK) strcat(buf, " LINK_OK");
	if(db[thing].flags & TEMPLE) strcat(buf, " TEMPLE");
#ifdef RESTRICTED_BUILDING
	if(db[thing].flags & BUILDER) strcat(buf, " BUILDER");
#endif /* RESTRICTED_BUILDING */
    }

    return buf;
}

void do_examine(dbref player, const char *name)
{
    dbref thing;
    dbref content;
    dbref exit;
    char buf[BUFFER_LEN];

    if(*name == '\0') {
	if((thing = getloc(player)) == NOTHING) return;
    } else {
	/* look it up */
	init_match(player, name, NOTYPE);
	match_exit();
	match_neighbor();
	match_possession();
	match_absolute();
	/* only Wizards can examine other players */
	if(Wizard(player)) match_player();
	match_here();
	match_me();

	/* get result */
	if((thing = noisy_match_result()) == NOTHING) return;
    }

    if(!can_link(player, thing)) {
	notify(player,
	       "You can only examine what you own.  Try using \"look.\"");
	return;
    }

    sprintf(buf, "%s(#%d) [%s] Key: %c%s(#%d) Pennies: %d %s",
	    getname(thing), thing,
	    getname(db[thing].owner),
	    db[thing].flags & ANTILOCK ? NOT_TOKEN : ' ',
	    getname(db[thing].key),
	    db[thing].key,
	    db[thing].pennies,
	    flag_description(thing));
    notify(player, buf);
    if(db[thing].description) notify(player, db[thing].description);
    if(db[thing].fail_message) {
	sprintf(buf, "Fail: %s", db[thing].fail_message);
	notify(player, buf);
    }
    if(db[thing].succ_message) {
	sprintf(buf, "Success: %s", db[thing].succ_message);
	notify(player, buf);
    }
    if(db[thing].ofail) {
	sprintf(buf, "Ofail: %s", db[thing].ofail);
	notify(player, buf);
    }
    if(db[thing].osuccess) {
	sprintf(buf, "Osuccess: %s", db[thing].osuccess);
	notify(player, buf);
    }

    /* show him the contents */
    if(db[thing].contents != NOTHING) {
	notify(player, "Contents:");
	DOLIST(content, db[thing].contents) {
	    notify_name(player, content);
	}
    }

    switch(Typeof(thing)) {
      case TYPE_ROOM:
	/* tell him about exits */
	if(db[thing].exits != NOTHING) {
	    notify(player, "Exits:");
	    DOLIST(exit, db[thing].exits) {
		notify_name (player, exit);
	    }
	} else {
	    notify(player, "No exits.");
	}

	/* print dropto if present */
	if(db[thing].location != NOTHING) {
	    sprintf(buf, "Dropped objects go to: %s(#%d)",
		    getname(db[thing].location), db[thing].location);
	    notify(player, buf);
	}
	break;
      case TYPE_THING:
      case TYPE_PLAYER:
	/* print home */
	sprintf(buf, "Home: %s(#%d)",
		getname(db[thing].exits), db[thing].exits); /* home */
	notify(player, buf);
	/* print location if player can link to it */
	if(db[thing].location != NOTHING
	   && (controls(player, db[thing].location)
	       || can_link_to(player, db[thing].location))) {
	    sprintf(buf, "Location: %s(#%d)",
		    getname(db[thing].location), db[thing].location);
	    notify(player, buf);
	}
	break;
      case TYPE_EXIT:
	/* print destination */
	switch(db[thing].location) {
	  case NOTHING:
	    break;
	  case HOME:
	    notify(player, "Destination: ***HOME***");
	    break;
	  default:
	    sprintf(buf, "%s: %s(#%d)",
		    (Typeof(db[thing].location) == TYPE_ROOM
		     ? "Destination" : "Carried by"),
		    getname(db[thing].location), db[thing].location);
	    notify(player, buf);
	    break;
	}
	break;
      default:
	/* do nothing */
	break;
    }
}

void do_score(dbref player) 
{
    char buf[BUFFER_LEN];

    sprintf(buf, "You have %d %s.",
	    db[player].pennies,
	    db[player].pennies == 1 ? "penny" : "pennies");
    notify(player, buf);
}

void do_inventory(dbref player)
{
    dbref thing;

    if((thing = db[player].contents) == NOTHING) {
	notify(player, "You aren't carrying anything.");
    } else {
	notify(player, "You are carrying:");
	DOLIST(thing, thing) {
	    notify_name(player, thing);
	}
    }

    do_score(player);
}

void do_find(dbref player, const char *name)
{
    dbref i;
    char buf[BUFFER_LEN];

    if(!payfor(player, LOOKUP_COST)) {
	notify(player, "You don't have enough pennies.");
    } else {
	for(i = 0; i < db_top; i++) {
	    if(Typeof(i) != TYPE_EXIT
	       && controls(player, i)
	       && (!*name || string_match(db[i].name, name))) {
		sprintf(buf, "%s(#%d)", db[i].name, i);
		notify(player, buf);
	    }
	}
	notify(player, "***End of List***");
    }
}
