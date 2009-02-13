#include "copyright.h"

#include <stdio.h>

#include "db.h"
#include "config.h"

/* Compute shortest path to each room */
/* Locks cost extra */
#define INFINITY 2148575	/* MAXINT or thereabouts */
#define LOCK_COST 10000		/* extra cost for a lock */

/* This code blasts a lot of fields in the database, so */
/* you don't ever want to write it back out afterwards. */

/* Where things get stored: */
/* cost to get here gets put in pennies */
/* location is the previous room that gets you here */
/* next is the next room in the search queue */
/* key non-zero means already queued */
/* contents is previous exit that gets you here */

/* this should be a priority queue, but we're cheap */
dbref search_queue_head = NOTHING;
dbref search_queue_tail = NOTHING;

void queue_room(dbref room)
{
    if(db[room].key) return;

    if(search_queue_tail == NOTHING) {
	search_queue_head = room;
    } else {
	db[search_queue_tail].next = room;
    }
    search_queue_tail = room;
    db[room].next = NOTHING;
    db[room].key = 1;
}

dbref dequeue_room()
{
    dbref room;

    if((room = search_queue_head) == NOTHING) return NOTHING;
    if((search_queue_head = db[room].next) == NOTHING) {
	search_queue_tail = NOTHING;
    }
    db[room].next = NOTHING;
    db[room].key = 0;

    return room;
}

void find_paths()
{
    dbref room;
    dbref exit;
    dbref mycost;		/* dbref[room].pennies */
    dbref cost;			/* mycost + cost to use exit */
    dbref dest;			/* exit destination */

    while((room = dequeue_room()) != NOTHING) {
	/* get first one */

	/* check its exits */
	mycost = db[room].pennies;
	DOLIST(exit, db[room].exits) {
	    if((dest = db[exit].location) < 0) continue;
	    cost = mycost + 1;
	    if(db[exit].key != NOTHING) {
		if(!(db[exit].flags & ANTILOCK)
		   && Typeof(db[exit].key) != TYPE_THING) {
		    continue;	/* we can't get it */
		} else {
		    cost += LOCK_COST;
		}
	    }
	    if(cost < db[dest].pennies) {
		/* it's cheaper, set and queue it */
		db[dest].pennies = cost;
		db[dest].location = room;
		db[dest].contents = exit;
		queue_room(dest);
	    }
	}
    }
}

void compute_paths(dbref start)
{
    dbref room;

    /* clear out all fields we use */
    for(room = 0; room < db_top; room++) {
	if(Typeof(room) == TYPE_ROOM) {
	    db[room].location = db[room].next = db[room].contents = NOTHING;
	    db[room].pennies = INFINITY;
	    db[room].key = 0;
	}
    }

    /* set up start */
    db[start].pennies = 0;
    queue_room(start);

    find_paths();
}

void print_path(dbref room)
{
    dbref prev;
    dbref exit;
    dbref key;

    if((prev = db[room].location) != NOTHING) {
	print_path(prev);
	exit = db[room].contents;
	if((key = db[exit].key) != NOTHING) {
	    printf("LOCKED[%s(%d)] ", db[key].name, key);
	}
	printf("%s => %s\n", db[exit].name, db[room].name);
    } 
}	

void print_paths()
{
    dbref room;

    for(room = 0; room < db_top; room++) {
	if(Typeof(room) == TYPE_ROOM) {
	    printf("%s(%d)[%s]: ",
		   db[room].name, room, db[db[room].owner].name);
	    if(db[room].pennies == INFINITY) {
		puts("UNREACHABLE");
	    } else {
		printf("%d + %d locks\n",
		       db[room].pennies % LOCK_COST,
		       db[room].pennies / LOCK_COST);
	    }
	    print_path(room);
	    putchar('\n');
	}
    }
}

void main(int argc, char **argv)
{
    dbref start = 0;

    if(argc >= 2) {
	start = atol(argv[2]);
    } else {
	start = PLAYER_START;
    }

    if(db_read(stdin) < 0) {
	fprintf(stderr, "%s: bad input\n", argv[0]);
	exit(5);
    }

    compute_paths(start);
    print_paths();

    exit(0);
}
