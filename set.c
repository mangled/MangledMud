#include "copyright.h"

/* commands which set parameters */
#include <stdio.h>
#include <ctype.h>

#include "db.h"
#include "config.h"
#include "match.h"
#include "interface.h"
#include "externs.h"

static dbref match_controlled(dbref player, const char *name)
{
    dbref match;

    init_match(player, name, NOTYPE);
    match_everything();

    match = noisy_match_result();
    if(match != NOTHING && !controls(player, match)) {
	notify(player, "Permission denied.");
	return NOTHING;
    } else {
	return match;
    }
}

void do_name(dbref player, const char *name, char *newname)
{
    dbref thing;
    void free(void *);
    char *password;

    if((thing = match_controlled(player, name)) != NOTHING) {
	/* check for bad name */
	if(*newname == '\0') {
	    notify(player, "Give it what new name?");
	    return;
	}

	/* check for renaming a player */
	if(Typeof(thing) == TYPE_PLAYER) {
	    /* split off password */
	    for(password = newname; isgraph(*password); password++);

	    /* eat whitespace */
	    if(*password) {
		*password++ = '\0'; /* terminate name */
		while(*password && isspace(*password)) password++;
	    }

	    /* check for null password */
	    if(!*password) {
		notify(player,
		       "You must specify a password to change a player name.");
		notify(player, "E.g.: name player = newname password");
		return;
	    } else if(strcmp(password, db[thing].password)) {
		notify(player, "Incorrect password.");
		return;
	    } else if(!payfor(player, LOOKUP_COST)
		      || !ok_player_name(newname)) {
		notify(player, "You can't give a player that name.");
		return;
	    }
	} else {
	    if(!ok_name(newname)) {
		notify(player, "That is not a reasonable name.");
		return;
	    }
	}

	/* everything ok, change the name */
	if(db[thing].name) {
	    free((void *) db[thing].name);
	}
	db[thing].name = alloc_string(newname);
	notify(player, "Name set.");
    }
}

void do_describe(dbref player, const char *name, const char *description)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	if(db[thing].description) {
	    free((void *) db[thing].description);
	}
	db[thing].description = alloc_string(description);
	notify(player, "Description set.");
    }
}

void do_fail(dbref player, const char *name, const char *message)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	if(db[thing].fail_message) {
	    free((void *) db[thing].fail_message);
	}
	db[thing].fail_message = alloc_string(message);
	notify(player, "Message set.");
    }
}

void do_success(dbref player, const char *name, const char *message)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	if(db[thing].succ_message) {
	    free((void *) db[thing].succ_message);
	}
	db[thing].succ_message = alloc_string(message);
	notify(player, "Message set.");
    }
}

void do_osuccess(dbref player, const char *name, const char *message)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	if(db[thing].osuccess) {
	    free((void *) db[thing].osuccess);
	}
	db[thing].osuccess = alloc_string(message);
	notify(player, "Message set.");
    }
}

void do_ofail(dbref player, const char *name, const char *message)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	if(db[thing].ofail) {
	    free((void *) db[thing].ofail);
	}
	db[thing].ofail = alloc_string(message);
	notify(player, "Message set.");
    }
}

void do_lock(dbref player, const char *name, const char *keyname)
{
    dbref thing;
    dbref key;
    int antilock;

    init_match(player, name, NOTYPE);
    match_everything();

    switch(thing = match_result()) {
      case NOTHING:
	notify(player, "I don't see what you want to lock!");
	return;
      case AMBIGUOUS:
	notify(player, "I don't know which one you want to lock!");
	return;
      default:
	if(!controls(player, thing)) {
	    notify(player, "You can't lock that!");
	    return;
	}
	break;
    }

    /* now we know it's ok to lock */
    if(antilock = (*keyname == NOT_TOKEN)) {
	/* skip past ! and any following whitespace */
	for(keyname++; *keyname && isspace(*keyname); keyname++);
    }
    
    /* match keyname */
    init_match(player, keyname, TYPE_THING);
    match_neighbor();
    match_possession();
    match_me();
    match_player();
    if(Wizard(player)) match_absolute();

    switch(key = match_result()) {
      case NOTHING:
	notify(player, "I can't find that key!");
	return;
      case AMBIGUOUS:
	notify(player, "I don't know which key you want!");
	return;
      default:
	if(Typeof(key) != TYPE_PLAYER
	   && Typeof(key) != TYPE_THING) {
	    notify(player, "Keys can only be players or things.");
	    return;
	}
	break;
    }
	
    /* everything ok, do it */
    db[thing].key = key;
    if(antilock) {
	db[thing].flags |= ANTILOCK;
	notify(player, "Anti-Locked.");
    } else {
	db[thing].flags &= ~ANTILOCK;
	notify(player, "Locked.");
    }
}

void do_unlock(dbref player, const char *name)
{
    dbref thing;

    if((thing = match_controlled(player, name)) != NOTHING) {
	db[thing].key = NOTHING;
	db[thing].flags &= ~ANTILOCK;
	notify(player, "Unlocked.");
    }
}

void do_unlink(dbref player, const char *name)
{
    dbref exit;

    init_match(player, name, TYPE_EXIT);
    match_exit();
    match_here();
    if(Wizard(player)) {
	match_absolute();
    }

    switch(exit = match_result()) {
      case NOTHING:
	notify(player, "Unlink what?");
	break;
      case AMBIGUOUS:
	notify(player, "I don't know which one you mean!");
	break;
      default:
	if(!controls(player, exit)) {
	    notify(player, "Permission denied.");
	} else {
	    switch(Typeof(exit)) {
	      case TYPE_EXIT:
		db[exit].location = NOTHING;
		notify(player, "Unlinked.");
		break;
	      case TYPE_ROOM:
		db[exit].location = NOTHING;
		notify(player, "Dropto removed.");
		break;
	      default:
		notify(player, "You can't unlink that!");
		break;
	    }
	}
    }
}

void do_chown(dbref player, const char *name, const char *newobj)
{
    dbref thing;
    dbref owner;

    if(!Wizard(player)) {
	notify(player, "Permission denied.");
    } else {
	init_match(player, name, NOTYPE);
	match_everything();

	if((thing = noisy_match_result()) == NOTHING) {
	    return;
	} else if((owner = lookup_player(newobj)) == NOTHING) {
	    notify(player, "I couldn't find that player.");
	} else if(Typeof(thing) == TYPE_PLAYER) {
	    notify(player, "Players always own themselves.");
	} else {
	    db[thing].owner = owner;
	    notify(player, "Owner changed.");
	}
    }
}

void do_set(dbref player, const char *name, const char *flag)
{
    dbref thing;
    const char *p;
    object_flag_type f;

    /* find thing */
    if((thing = match_controlled(player, name)) == NOTHING) return;

    /* move p past NOT_TOKEN if present */
    for(p = flag; *p && (*p == NOT_TOKEN || isspace(*p)); p++);

    /* identify flag */
    if(*p == '\0') {
	notify(player, "You must specify a flag to set.");
	return;
    } else if(string_prefix("LINK_OK", p)) {
	f = LINK_OK;
    } else if(string_prefix("DARK", p)) {
	f = DARK;
    } else if(string_prefix("STICKY", p)) {
	f = STICKY;
    } else if(string_prefix("WIZARD", p)) {
	f = WIZARD;
    } else if(string_prefix("TEMPLE", p)) {
	f = TEMPLE;
#ifdef RESTRICTED_BUILDING
    } else if(string_prefix("BUILDER", p)) {
	f = BUILDER;
#endif /* RESTRICTED_BUILDING */
    } else {
	notify(player, "I don't recognized that flag.");
	return;
    }

    /* check for restricted flag */
    if(!Wizard(player)
       && (f == WIZARD
#ifdef RESTRICTED_BUILDING
	   || f == BUILDER
#endif /* RESTRICTED_BUILDING */
	   || f == TEMPLE
	   || f == DARK && Typeof(thing) != TYPE_ROOM)) {
	notify(player, "Permission denied.");
	return;
    }

    /* check for stupid wizard */
    if(f == WIZARD && *flag == NOT_TOKEN && thing == player) {
	notify(player, "You cannot make yourself mortal.");
	return;
    }

    /* else everything is ok, do the set */
    if(*flag == NOT_TOKEN) {
	/* reset the flag */
	db[thing].flags &= ~f;
	notify(player, "Flag reset.");
    } else {
	/* set the flag */
	db[thing].flags |= f;
	notify(player, "Flag set.");
    }
}

