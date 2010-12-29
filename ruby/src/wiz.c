#include "copyright.h"

/* Wizard-only commands */
#include <stdlib.h>

#include "db.h"
#include "interface.h"
#include "match.h"
#include "move.h"
#include "player.h"
#include "interface.h"
#include "wiz.h"

void do_teleport(dbref player, const char *arg1, const char *arg2)
{
    dbref victim;
    dbref destination;
    const char *to;

    if(!Wizard(player)) {
	notify(player, "Only a Wizard may teleport at will.");
	return;
    }

    /* get victim, destination */
    if(*arg2 == '\0') {
	victim = player;
	to = arg1;
    } else {
	init_match(player, arg1, NOTYPE);
	match_neighbor();
	match_possession();
	match_me();
	match_absolute();
	match_player();

	if((victim = noisy_match_result()) == NOTHING) {
	    return;
	}
	to = arg2;
    }

    /* get destination */
    init_match(player, to, TYPE_PLAYER);
    match_neighbor();
    match_me();
    match_here();
    match_absolute();
    match_player();

    switch(destination = match_result()) {
      case NOTHING:
	notify(player, "Send it where?");
	break;
      case AMBIGUOUS:
	notify(player, "I don't know which destination you mean!");
	break;
      default:
	/* check victim, destination types, teleport if ok */
	if(Typeof(destination) == TYPE_EXIT
	   || Typeof(destination) == TYPE_THING
	   || Typeof(victim) == TYPE_EXIT
	   || Typeof(victim) == TYPE_ROOM
	   || (Typeof(victim) == TYPE_PLAYER
	       && Typeof(destination) != TYPE_ROOM)) {
	    notify(player, "Bad destination.");
	} else if(Typeof(victim) == TYPE_PLAYER) {
	    notify(victim, "You feel a wrenching sensation...");
	    enter_room(victim, destination);
	} else {
	    moveto(victim, destination);
	}
    }
}

void do_force(dbref player, const char *what, char *command)
{
    dbref victim;

    if(!Wizard(player)) {
	notify(player, "Only Wizards may use this command.");
	return;
    }

    /* get victim */
    if((victim = lookup_player(what)) == NOTHING) {
	notify(player, "That player does not exist.");
	return;
    }

    /* force victim to do command */
    process_command(victim, command);
}

void do_stats(dbref player, const char *name)
{
    dbref rooms;
    dbref exits;
    dbref things;
    dbref players;
    dbref unknowns;
    dbref total;
    dbref i;
    dbref owner;
    char buf[BUFFER_LEN];

    if(!Wizard(player)) {
	sprintf(buf, "The universe contains %d objects.", db_top);
	notify(player, buf);
    } else {
	owner = lookup_player(name);
	total = rooms = exits = things = players = unknowns = 0;
	for(i = 0; i < db_top; i++) {
	    if(owner == NOTHING || owner == db[i].owner) {
		total++;
		switch(Typeof(i)) {
		  case TYPE_ROOM:
		    rooms++;
		    break;
		  case TYPE_EXIT:
		    exits++;
		    break;
		  case TYPE_THING:
		    things++;
		    break;
		  case TYPE_PLAYER:
		    players++;
		    break;
		  default:
		    unknowns++;
		    break;
		}
	    }
	}
	sprintf(buf,
		"%d objects = %d rooms, %d exits, %d things, %d players, %d unknowns.",
		total, rooms, exits, things, players, unknowns);
	notify(player, buf);
    }
}
		
void do_toad(dbref player, const char *name)
{
    dbref victim;
    char buf[BUFFER_LEN];

    if(!Wizard(player)) {
	notify(player, "Only a Wizard can turn a person into a toad.");
	return;
    }

    init_match(player, name, TYPE_PLAYER);
    match_neighbor();
    match_absolute();
    match_player();
    if((victim = noisy_match_result()) == NOTHING) return;

    if(Typeof(victim) != TYPE_PLAYER) {
	notify(player, "You can only turn players into toads!");
    } else if(Wizard(victim)) {
	notify(player, "You can't turn a Wizard into a toad.");
    } else if(db[victim].contents != NOTHING) {
	notify(player, "What about what they are carrying?");
    } else {
	/* we're ok */
	/* do it */
	if(db[victim].password) {
	    free((void*) db[victim].password);
	    db[victim].password = 0;
	}
	db[victim].flags = TYPE_THING;
	db[victim].owner = player; /* you get it */
	db[victim].pennies = 1;	/* don't let him keep his immense wealth */

	/* notify people */
	notify(victim, "You have been turned into a toad.");
	sprintf(buf, "You turned %s into a toad!", db[victim].name);
	notify(player, buf);

	/* reset name */
	sprintf(buf, "a slimy toad named %s", db[victim].name);
	free((void*) db[victim].name);
	db[victim].name = alloc_string(buf);
    }
}
