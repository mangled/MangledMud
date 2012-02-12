#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "db.h"
#include "config.h"
#include "interface.h"

#define DOWNCASE(x) (isupper(x) ? tolower(x) : (x))

dbref lookup_player(const char *name);

int string_compare(const char *s1, const char *s2)
{
    while(*s1 && *s2 && DOWNCASE(*s1) == DOWNCASE(*s2)) s1++, s2++;

    return(DOWNCASE(*s1) - DOWNCASE(*s2));
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

/* don't use this, it's expensive */
/* maybe soon we'll put in a hash table */
dbref lookup_player(const char *name)
{
    dbref i;

    for(i = 0; i < db_top; i++) {
	if(Typeof(i) == TYPE_PLAYER
	   && db[i].name && !string_compare(db[i].name, name)) return i;
    }
    return NOTHING;
}

dbref connect_player(const char *name, const char *password)
{
    dbref player;

    if((player = lookup_player(name)) == NOTHING) return NOTHING;
    if(db[player].password
       && *db[player].password
       &&strcmp(db[player].password, password)) return NOTHING;

    return player;
}

dbref create_player(const char *name, const char *password)
{
    dbref player;

    if(!ok_player_name(name)) return NOTHING;

    /* else he doesn't already exist, create him */
    player = new_object();

    /* initialize everything */
    db[player].name = alloc_string(name);
    db[player].location = PLAYER_START;
    db[player].exits = PLAYER_START;	/* home */
    db[player].owner = player;
    db[player].flags = TYPE_PLAYER;
    db[player].password = alloc_string(password);
    
    /* link him to PLAYER_START */
    PUSH(player, db[PLAYER_START].contents);

    return player;
}

void do_password(dbref player, const char *old, const char *newobj)
{
    if(strcmp(old, db[player].password)) {
	notify(player, "Sorry");
    } else {
	free((void*) db[player].password);
	db[player].password = alloc_string(newobj);
	notify(player, "Password changed.");
    }
}
