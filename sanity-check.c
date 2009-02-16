#include "copyright.h"

#include <stdlib.h>

#include "db.h"
#include "config.h"
#include "externs.h"

void check_exits(dbref i)
{
    dbref exit;
    int count;

    count = 10000;
    for(exit = db[i].exits;
	exit != NOTHING;
	exit = db[exit].next) {
	if(exit < 0 || exit >= db_top || Typeof(exit) != TYPE_EXIT) {
	    printf("%d has bad exit %d\n", i, exit);
	    break;
	}

	/* set type of exit to be really strange */
	db[exit].flags = 4;	/* nonexistent type */

	if(count-- < 0) {
	    printf("%d has looping exits\n", i);
	    break;
	}
    }
}

void check_contents(dbref i)
{
    dbref thing;
    dbref loc;
    int count;

    count = 10000;
    for(thing = db[i].contents;
	thing != NOTHING;
	thing = db[thing].next) {
	if(thing < 0 || thing >= db_top || Typeof(thing) == TYPE_ROOM) {
	    printf("%d contains bad object %d\n", i, thing);
	    break;
	} else if((loc = db[thing].location) != i) {
	    printf("%d in %d but location is %d\n", thing, i, loc);
	} else if(Typeof(thing) == TYPE_EXIT) {
	    db[thing].flags = 4; /* nonexistent type */
	}
	if(count-- < 0) {
	    printf("%d has looping contents\n", i);
	    break;
	}
    }
}

void check_location(dbref i)
{
    dbref loc;

    loc = db[i].location;
    if(loc < 0 || loc >= db_top) {
	printf("%d has bad loc %d\n", i, loc);
    } else if(!member(i, db[loc].contents)) {
	printf("%d not in loc %d\n", i, loc);
    }
}

void check_pennies(dbref i)
{
    dbref pennies;

    pennies = db[i].pennies;

    switch(Typeof(i)) {
      case TYPE_ROOM:
      case TYPE_EXIT:
	break;
      case TYPE_PLAYER:
	if(pennies < 0 || pennies > MAX_PENNIES+100) {
	    printf("Player %s(%d) has %d pennies\n", db[i].name, i, pennies);
	}
	break;
      case TYPE_THING:
	if(pennies < 0 || pennies > MAX_OBJECT_ENDOWMENT) {
	    printf("Object %s(%d) endowed with %d pennies\n",
		   db[i].name, i, pennies);
	}
	break;
    }
}

int main(void)
{
    dbref i;

    if(db_read(stdin) < 0) {
	puts("Database load failed!");
	exit(1);
    } 

    puts("Done loading database");

    for(i = 0; i < db_top; i++) {
	check_pennies(i);
	switch(Typeof(i)) {
	  case TYPE_PLAYER:
	    check_contents(i);
	    check_location(i);
	    if(Wizard(i)) printf("Wizard: %s(%d)\n", db[i].name, i);
	    break;
	  case TYPE_THING:
	    check_location(i);
	    break;
	  case TYPE_ROOM:
	    check_contents(i);
	    check_exits(i);
	    break;
	}
    }

    /* scan for unattached exits */
    for(i = 0; i < db_top; i++) {
	if(Typeof(i) == TYPE_EXIT) {
	    printf("Unattached exit %d\n", i);
	}
    }
	    
    exit(0);
}
