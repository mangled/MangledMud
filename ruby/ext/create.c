#include "copyright.h"

/* Commands that create new objects */

#include "db.h"
#include "config.h"
#include "interface.h"
#include "stringutil.h"
#include "predicates.h"
#include "create.h"
#include "match.h"

/* utility for open and link */
static dbref parse_linkable_room(dbref player, const char *room_name)
{
    dbref room;

    /* parse room */
    if(!string_compare(room_name, "here")) {
	room = db[player].location;
    } else if(!string_compare(room_name, "home")) {
	return HOME;		/* HOME is always linkable */
    } else {
	room = parse_dbref(room_name);
    }

    /* check room */
    if(room < 0 || room >= db_top
       || Typeof(room) != TYPE_ROOM) {
	notify(player, "That's not a room!");
	return NOTHING;
    } else if(!can_link_to(player, room)) {
	notify(player, "You can't link to that.");
	return NOTHING;
    } else {
	return room;
    }
}

/* use this to create an exit */
void do_open(dbref player, const char *direction, const char *linkto)
{
    dbref loc;
    dbref exit;

#ifdef RESTRICTED_BUILDING
    if(!Builder(player)) {
	notify(player, "That command is restricted to authorized builders.");
	return;
    }
#endif /* RESTRICTED_BUILDING */

    if((loc = getloc(player)) == NOTHING) return;

    if(!*direction) {
		notify(player, "Open where?");
		return;
    } else if(!ok_name(direction)) {
		notify(player, "That's a strange name for an exit!");
		return;
    }

    if(!controls(player, loc)) {
		notify(player, "Permission denied.");
    } else if(!payfor(player, EXIT_COST)) {
		notify(player,
	       "Sorry, you don't have enough pennies to open an exit.");
    } else {
		/* create the exit */
		exit = new_object();
	
		/* initialize everything */
		db[exit].name = alloc_string(direction);
		db[exit].owner = player;
		db[exit].flags = TYPE_EXIT;
	
		/* link it in */
		PUSH(exit, db[loc].exits);
	
		/* and we're done */
		notify(player, "Opened.");
	
		/* check second arg to see if we should do a link */
		if(*linkto != '\0') {
			notify(player, "Trying to link...");
			if((loc = parse_linkable_room(player, linkto)) != NOTHING) {
				if(!payfor(player, LINK_COST)) {
					notify(player, "You don't have enough pennies to link.");
				} else {
					/* it's ok, link it */
					db[exit].location = loc;
					notify(player, "Linked.");
				}
			}
		}
    }
}

/* use this to link to a room that you own */
/* it seizes ownership of the exit */
/* costs 1 penny */
/* plus a penny transferred to the exit owner if they aren't you */
/* you must own the linked-to room AND specify it by room number */
void do_link(dbref player, const char *name, const char *room_name)
{
    dbref loc;
    dbref thing;
    dbref room;

    if((loc = getloc(player)) == NOTHING) return;
    if((room = parse_linkable_room(player, room_name)) == NOTHING) return;

    init_match(player, name, TYPE_EXIT);
    match_exit();
    match_neighbor();
    match_possession();
    match_me();
    match_here();
    if(Wizard(player)) {
	match_absolute();
	match_player();
    }

    if((thing = noisy_match_result()) != NOTHING) {
	switch(Typeof(thing)) {
	  case TYPE_EXIT:
	    /* we're ok, check the usual stuff */
	    if(db[thing].location != NOTHING) {
			if(controls(player, thing)) {
				if(Typeof(db[thing].location) == TYPE_PLAYER) {
				notify(player, "That exit is being carried.");
				} else {
				notify(player, "That exit is already linked.");
				}
			} else {
				notify(player, "Permission denied.");
			}
	    } else {
			/* handle costs */
			if(db[thing].owner == player) {
				if(!payfor(player, LINK_COST)) {
					notify(player, "It costs a penny to link this exit.");
					return;
				}
			} else {
				if(!payfor(player, LINK_COST + EXIT_COST)) {
					notify(player, "It costs two pennies to link this exit.");
					return;
	#ifdef RESTRICTED_BUILDING
				} else if(!Builder(player)) {
					notify(player, "Only authorized builders may seize exits.");
	#endif /* RESTRICTED_BUILDING */			
				} else {
					/* pay the owner for his loss */
					db[db[thing].owner].pennies += EXIT_COST;
				}
			}
	
			/* link has been validated and paid for; do it */
			db[thing].owner = player;
			db[thing].location = room;
	
			/* notify the player */
			notify(player, "Linked.");
	    }
	    break;
	  case TYPE_THING:
	  case TYPE_PLAYER:
	    if(!controls(player, thing)) {
		notify(player, "Permission denied.");
	    } else if(room == HOME) {
		notify(player, "Can't set home to home.");
	    } else {
		/* do the link */
		db[thing].exits = room; /* home */
		notify(player, "Home set.");
	    }
	    break;
	  case TYPE_ROOM:
	    if(!controls(player, thing)) {
		notify(player, "Permission denied.");
	    } else {
		/* do the link, in location */
		db[thing].location = room; /* dropto */
		notify(player, "Dropto set.");
	    }
	    break;
	  default:
	    notify(player, "Internal error: weird object type.");
	    fprintf(stderr, "PANIC weird object: Typeof(%d) = %d\n",
		    thing, Typeof(thing));
	    break;
	}
    }
}

/* use this to create a room */
void do_dig(dbref player, const char *name)
{
    dbref room;
    char buf[BUFFER_LEN];

#ifdef RESTRICTED_BUILDING
    if(!Builder(player)) {
	notify(player, "That command is restricted to authorized builders.");
	return;
    }
#endif /* RESTRICTED_BUILDING */

    /* we don't need to know player's location!  hooray! */
    if(*name == '\0') {
	notify(player, "Dig what?");
    } else if(!ok_name(name)) {
	notify(player, "That's a silly name for a room!");
    } else if(!payfor(player, ROOM_COST)) {
	notify(player, "Sorry, you don't have enough pennies to dig a room.");
    } else {
	room = new_object();

	/* Initialize everything */
	db[room].name = alloc_string(name);
	db[room].owner = player;
	db[room].flags = TYPE_ROOM;

	sprintf(buf, "%s created with room number %d.", name, room);
	notify(player, buf);
    }
}

/* use this to create an object */
void do_create(dbref player, char *name, int cost)
{
    dbref loc;
    dbref thing;

#ifdef RESTRICTED_BUILDING
    if(!Builder(player)) {
	notify(player, "That command is restricted to authorized builders.");
	return;
    }
#endif /* RESTRICTED_BUILDING */

    if(*name == '\0') {
	notify(player, "Create what?");
	return;
    } else if(!ok_name(name)) {
	notify(player, "That's a silly name for a thing!");
	return;
    } else if(cost < 0) {
	notify(player, "You can't create an object for less than nothing!");
	return;
    } else if(cost < OBJECT_COST) {
	cost = OBJECT_COST;
    }

    if(!payfor(player, cost)) {
	notify(player, "Sorry, you don't have enough pennies.");
    } else {
	/* create the object */
	thing = new_object();

	/* initialize everything */
	db[thing].name = alloc_string(name);
	db[thing].location = player;
	db[thing].owner = player;
	db[thing].pennies = OBJECT_ENDOWMENT(cost);
	db[thing].flags = TYPE_THING;

	/* endow the object */
	if(db[thing].pennies > MAX_OBJECT_ENDOWMENT) {
	    db[thing].pennies = MAX_OBJECT_ENDOWMENT;
	}

	/* home is here (if we can link to it) or player's home */
	if((loc = db[player].location) != NOTHING
	   && can_link_to(player, loc)) {
	    db[thing].exits = loc;	/* home */
	} else {
	    db[thing].exits = db[player].exits;	/* home */
	}

	/* link it in */
	PUSH(thing, db[player].contents);

	/* and we're done */
	notify(player, "Created.");
    }
}

