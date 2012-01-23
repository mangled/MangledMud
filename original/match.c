#include "copyright.h"

/* Routines for parsing arguments */
#include <stdlib.h>
#include <ctype.h>

#include "db.h"
#include "config.h"
#include "externs.h"
#include "interface.h"
#include "match.h"

#define DOWNCASE(x) (isupper(x) ? tolower(x) : (x))

static dbref exact_match = NOTHING;	/* holds result of exact match */
static int check_keys = 0;	/* if non-zero, check for keys */
static dbref last_match = NOTHING;	/* holds result of last match */
static int match_count;		/* holds total number of inexact matches */
static dbref match_who;	/* player who is being matched around */
static const char *match_name;	/* name to match */
static int preferred_type = NOTYPE; /* preferred type */

void init_match(dbref player, const char *name, int type)
{
    exact_match = last_match = NOTHING;
    match_count = 0;
    match_who = player;
    match_name = name;
    check_keys = 0;
    preferred_type = type;
}

void init_match_check_keys(dbref player, const char *name, int type)
{
    init_match(player, name, type);
    check_keys = 1;
}

static dbref choose_thing(dbref thing1, dbref thing2)
{
    int has1;
    int has2;

    if(thing1 == NOTHING) {
	return thing2;
    } else if(thing2 == NOTHING) {
	return thing1;
    }

    if(preferred_type != NOTYPE) {
	if(Typeof(thing1) == preferred_type) {
	    if(Typeof(thing2) != preferred_type) {
		return thing1;
	    }
	} else if(Typeof(thing2) == preferred_type) {
	    return thing2;
	}
    }

    if(check_keys) {
	has1 = could_doit(match_who, thing1);
	has2 = could_doit(match_who, thing2);

	if(has1 && !has2) {
	    return thing1;
	} else if (has2 && !has1) {
	    return thing2;
	}
	/* else fall through */
    }

    return (random() % 2 ? thing1 : thing2);
}

void match_player()
{
    dbref match;
    const char *p;

    if(*match_name == LOOKUP_TOKEN
       && payfor(match_who, LOOKUP_COST)) {
	for(p = match_name + 1; isspace(*p); p++);
	if((match = lookup_player(p)) != NOTHING) {
	    exact_match = match;
	}
    }
}

/* returns nnn if name = #nnn, else NOTHING */
static dbref absolute_name()
{
    dbref match;

    if(*match_name == NUMBER_TOKEN) {
	match = parse_dbref(match_name+1);
	if(match < 0 || match >= db_top) {
	    return NOTHING;
	} else {
	    return match;
	}
    } else {
	return NOTHING;
    }
}

void match_absolute()
{
    dbref match;

    if((match = absolute_name()) != NOTHING) {
	exact_match = match;
    }
}

void match_me()
{
    if(!string_compare(match_name, "me")) {
	exact_match = match_who;
    }
}

void match_here()
{
    if(!string_compare(match_name, "here")
       && db[match_who].location != NOTHING) {
	exact_match = db[match_who].location;
    }
}

static void match_list(dbref first)
{
    dbref absolute;

    absolute = absolute_name();
    if(!controls(match_who, absolute)) absolute = NOTHING;

    DOLIST(first, first) {
	if(first == absolute) {
	    exact_match = first;
	    return;
	} else if(!string_compare(db[first].name, match_name)) {
	    /* if there are multiple exact matches, randomly choose one */
	    exact_match = choose_thing(exact_match, first);
	} else if(string_match(db[first].name, match_name)) {
	    last_match = first;
	    match_count++;
	}
    }
}
    
void match_possession()
{
    match_list(db[match_who].contents);
}

void match_neighbor()
{
    dbref loc;

    if((loc = db[match_who].location) != NOTHING) {
	match_list(db[loc].contents);
    }
}

void match_exit()
{
    dbref loc;
    dbref exit;
    int exit_status;
    dbref absolute;
    const char *match;
    const char *p;

    if((loc = db[match_who].location) != NOTHING) {
	absolute = absolute_name();
	if(!controls(match_who, absolute)) absolute = NOTHING;

	DOLIST(exit, db[loc].exits) {
	    if(exit == absolute) {
		exact_match = exit;
	    } else {
		match = db[exit].name;
		while(*match) {
		    /* check out this one */
		    for(p = match_name;
			(*p
			 && DOWNCASE(*p) == DOWNCASE(*match)
			 && *match != EXIT_DELIMITER);
			p++, match++);
		    /* did we get it? */
		    if(*p == '\0') {
			/* make sure there's nothing afterwards */
			while(isspace(*match)) match++;
			if(check_keys) {
			    exit_status = could_doit(match_who, exit);
			} else {
			    exit_status = 1;
			}
			if(*match == '\0' || *match == EXIT_DELIMITER) {
			    /* we got it */
			    exact_match = choose_thing(exact_match, exit);
			    goto next_exit;	/* got this match */
			}
		    }
		    /* we didn't get it, find next match */
		    while(*match && *match++ != EXIT_DELIMITER);
		    while(isspace(*match)) match++;
		}
	    }
	  next_exit:
	    ;
	}
    }
    // Stop GCC complaining - Note there is a bug related to this which we have
    // fixed in the code being ported, see, ext/match.c
    exit_status = exit_status;
}

void match_everything()
{
    match_exit();
    match_neighbor();
    match_possession();
    match_me();
    match_here();
    if(Wizard(match_who)) {
	match_absolute();
	match_player();
    }
}

dbref match_result()
{
    if(exact_match != NOTHING) {
	return exact_match;
    } else {
	switch(match_count) {
	  case 0:
	    return NOTHING;
	  case 1:
	    return last_match;
	  default:
	    return AMBIGUOUS;
	}
    }
}
	   
/* use this if you don't care about ambiguity */
dbref last_match_result()
{
    if(exact_match != NOTHING) {
	return exact_match;
    } else {
	return last_match;
    }
}

dbref noisy_match_result()
{
    dbref match;

    switch(match = match_result()) {
      case NOTHING:
	notify(match_who, NOMATCH_MESSAGE);
	return NOTHING;
      case AMBIGUOUS:
	notify(match_who, AMBIGUOUS_MESSAGE);
	return NOTHING;
      default:
	return match;
    }
}

