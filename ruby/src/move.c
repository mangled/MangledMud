#include "copyright.h"

#include <stdlib.h>

#include "db.h"
#include "config.h"
#include "interface.h"
#include "match.h"
#include "move.h"
#include "utils.h"
#include "speech.h"
#include "stringutil.h"
#include "predicates.h"
#include "look.h"

void moveto(dbref what, dbref where)
{
    dbref loc;

    /* remove what from old loc */
    if((loc = db[what].location) != NOTHING) {
	db[loc].contents = remove_first(db[loc].contents, what);
    }

    /* test for special cases */
    switch(where) {
      case NOTHING:
	db[what].location = NOTHING;
	return;			/* NOTHING doesn't have contents */
      case HOME:
	where = db[what].exits;	/* home */
	break;
    }

    /* now put what in where */
    PUSH(what, db[where].contents);

    db[what].location = where;
}

static void send_contents(dbref loc, dbref dest)
{
    dbref first;
    dbref rest;

    first = db[loc].contents;
    db[loc].contents = NOTHING;

    /* blast locations of everything in list */
    DOLIST(rest, first) {
	db[rest].location = NOTHING;
    }

    while(first != NOTHING) {
	rest = db[first].next;
	if(Typeof(first) != TYPE_THING) {
	    moveto(first, loc);
	} else {
	    moveto(first, (db[first].flags & STICKY) ? HOME : dest);
	}
	first = rest;
    }

    db[loc].contents = reverse(db[loc].contents);
}

void maybe_dropto(dbref loc, dbref dropto)
{
    dbref thing;

    if(loc == dropto) return;	/* bizarre special case */

    /* check for players */
    DOLIST(thing, db[loc].contents) {
	if(Typeof(thing) == TYPE_PLAYER) return;
    }
    
    /* no players, send everything to the dropto */
    send_contents(loc, dropto);
}

void enter_room(dbref player, dbref loc)
{
    dbref old;
    dbref dropto;
    char buf[BUFFER_LEN];

    /* check for room == HOME */
    if(loc == HOME) loc = db[player].exits; /* home */

    /* get old location */
    old = db[player].location;

    /* check for self-loop */
    /* self-loops don't do move or other player notification */
    /* but you still get autolook and penny check */
    if(loc != old) {
		if(old != NOTHING) {
			/* notify others unless DARK */
			if(!Dark(old) && !Dark(player)) {
				sprintf(buf, "%s has left.", db[player].name);
				notify_except(db[old].contents, player, buf);
			}
		}
	
		/* go there */
		moveto(player, loc);
	
		/* if old location has STICKY dropto, send stuff through it */
		if(old != NOTHING && (dropto = db[old].location) != NOTHING && (db[old].flags & STICKY)) {
			maybe_dropto(old, dropto);
		}
	
		/* tell other folks in new location if not DARK */
		if(!Dark(loc) && !Dark(player)) {
			sprintf(buf, "%s has arrived.", db[player].name);
			notify_except(db[loc].contents, player, buf);
		}
    }

    /* autolook */
    look_room(player, loc);

    /* check for pennies */
    if(!controls(player, loc) && db[player].pennies <= MAX_PENNIES && random() % PENNY_RATE == 0) {
		notify(player, "You found a penny!");
		db[player].pennies++;
    }
}
	    
void send_home(dbref thing)
{
    switch(Typeof(thing)) {
      case TYPE_PLAYER:
		/* send his possessions home first! */
		/* that way he sees them when he arrives */
		send_contents(thing, HOME);
		enter_room(thing, db[thing].exits); /* home */
	break;
      case TYPE_THING:
		moveto(thing, db[thing].exits);	/* home */
	break;
      default:
		/* no effect */
	break;
    }
}
    
int can_move(dbref player, const char *direction)
{
    if(!string_compare(direction, "home")) return 1;

    /* otherwise match on exits */
    init_match(player, direction, TYPE_EXIT);
    match_exit();
    return(last_match_result() != NOTHING);
}

void do_move(dbref player, const char *direction)
{
    dbref exit;
    dbref loc;
    char buf[BUFFER_LEN];

    if(!string_compare(direction, "home")) {
	/* send him home */
	/* but steal all his possessions */
	if((loc = db[player].location) != NOTHING) {
	    /* tell everybody else */
	    sprintf(buf, "%s goes home.", db[player].name);
	    notify_except(db[loc].contents, player, buf);
	}
	/* give the player the messages */
	notify(player, "There's no place like home...");
	notify(player, "There's no place like home...");
	notify(player, "There's no place like home...");
	notify(player, "You wake up back home, without your possessions.");
	send_home(player);
    } else {
	/* find the exit */
	init_match_check_keys(player, direction, TYPE_EXIT);
	match_exit();
	switch(exit = match_result()) {
	  case NOTHING:
	    notify(player, "You can't go that way.");
	    break;
	  case AMBIGUOUS:
	    notify(player, "I don't know which way you mean!");
	    break;
	  default:
	    /* we got one */
	    /* check to see if we got through */
	    if(can_doit(player, exit, "You can't go that way.")) {
		enter_room(player, db[exit].location);
	    }
	    break;
	}
    }
}

void do_get(dbref player, const char *what)
{
    dbref loc;
    dbref thing;

    init_match_check_keys(player, what, TYPE_THING);
    match_neighbor();
    match_exit();
    if(Wizard(player)) match_absolute(); /* the wizard has long fingers */

    if((thing = noisy_match_result()) != NOTHING) {
	if(db[thing].location == player) {
	    notify(player, "You already have that!");
	    return;
	}
	switch(Typeof(thing)) {
	  case TYPE_THING:
	    if(can_doit(player, thing, "You can't pick that up.")) {
		moveto(thing, player);
		notify(player, "Taken.");
	    }
	    break;
	  case TYPE_EXIT:
	    if(!controls(player, thing)) {
		notify(player, "You can't pick that up.");
	    } else if(db[thing].location != NOTHING) {
		notify(player, "You can't pick up a linked exit.");
#ifdef RESTRICTED_BUILDING
	    } else if(!Builder(player)) {
		notify(player, "Only authorized builders may pick up exits.");
#endif /* RESTRICTED_BUILDING */
	    } else {
		/* take it out of location */
		if((loc = getloc(player)) == NOTHING) return;
		if(!member(thing, db[loc].exits)) {
		    notify(player,
			   "You can't pick up an exit from another room.");
		    return;
		}
		db[loc].exits = remove_first(db[loc].exits, thing);
		PUSH(thing, db[player].contents);
		db[thing].location = player;
		notify(player, "Exit taken.");
	    }
	    break;
	  default:
	    notify(player, "You can't take that!");
	    break;
	}
    }
}

void do_drop(dbref player, const char *name)
{
    dbref loc;
    dbref thing;
    char buf[BUFFER_LEN];
    int reward;

    if((loc = getloc(player)) == NOTHING) return;    

    init_match(player, name, TYPE_THING);
    match_possession();

    switch(thing = match_result()) {
      case NOTHING:
	notify(player, "You don't have that!");
	break;
      case AMBIGUOUS:
	notify(player, "I don't know which you mean!");
	break;
      default:
	if(db[thing].location != player) {
	    /* Shouldn't ever happen. */
	    notify(player, "You can't drop that.");
	} else if(Typeof(thing) == TYPE_EXIT) {
	    /* special behavior for exits */
	    if(!controls(player, loc)) {
		notify(player, "You can't put an exit down here.");
		return;
	    }
	    /* else we can put it down */
	    moveto(thing, NOTHING); /* take it out of the pack */
	    PUSH(thing, db[loc].exits);
	    notify(player, "Exit dropped.");
	} else if(db[loc].flags & TEMPLE) {
	    /* sacrifice time */
	    send_home(thing);
	    sprintf(buf,
		    "%s is consumed in a burst of flame!", db[thing].name);
	    notify(player, buf);
	    sprintf(buf, "%s sacrifices %s.",
		    db[player].name, db[thing].name);
	    notify_except(db[loc].contents, player, buf);

	    /* check for reward */
	    if(!controls(player, thing)) {
		reward = db[thing].pennies;
		if(reward < 1 || db[player].pennies > MAX_PENNIES) {
		    reward = 1;
		} else if(reward > MAX_OBJECT_ENDOWMENT) {
		    reward = MAX_OBJECT_ENDOWMENT;
		}

		db[player].pennies += reward;
		sprintf(buf,
			"You have received %d %s for your sacrifice.",
			reward,
			reward == 1 ? "penny" : "pennies");
		notify(player, buf);
	    }
	} else if(db[thing].flags & STICKY) {
	    send_home(thing);
	    notify(player, "Dropped.");
	} else if(db[loc].location != NOTHING && !(db[loc].flags & STICKY)) {
	    /* location has immediate dropto */
	    moveto(thing, db[loc].location);
	    notify(player, "Dropped.");
	} else {
	    moveto(thing, loc);
	    notify(player, "Dropped.");
	    sprintf(buf, "%s dropped %s.", db[player].name, db[thing].name);
	    notify_except(db[loc].contents, player, buf);
	}
	break;
    }
}
