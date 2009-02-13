#include "copyright.h"

#include <stdio.h>
#include <sys/param.h>

#include "db.h"

int include_all = 0;		/* include everything unless specified */

dbref included[NCARGS+1];
dbref excluded[NCARGS+1];

dbref *trans;			/* translation vector */

#define DEFAULT_LOCATION (0)
#define DEFAULT_OWNER (1)

/* returns 1 if it is not excluded */
int not_excluded(dbref x)
{
    int i;

    /* check that it isn't excluded */
    for(i = 0; excluded[i] != NOTHING; i++) {
	if(excluded[i] == x) return 0; /* always exclude specifics */
    }
    
    /* if it's an exit, check that its destination is ok */
    if(Typeof(x) == TYPE_EXIT) {
	return isok(db[x].location);
    } else {
	return 1;
    }
}

/* returns 1 if it should be included in translation vector */
int isok(dbref x)
{
    int i;

    if(x == DEFAULT_OWNER || x == DEFAULT_LOCATION) return 1;

    for(i = 0; included[i] != NOTHING; i++) {
	if(included[i] == x) return 1; /* always get specific ones */
	if(included[i] == db[x].owner) {
	    return not_excluded(x);
	}
    }

    /* not in the list, can only get it if include_all is on */
    /* or it's owned by DEFAULT_OWNER */
    return ((include_all || db[x].owner == DEFAULT_OWNER) && not_excluded(x));
}

void build_trans(void)
{
    dbref i;
    dbref val;

    if((trans = (dbref *) malloc(sizeof(dbref) * db_top)) == 0) {
	abort();
    }

    val = 0;
    for(i = 0; i < db_top; i++) {
	if(isok(i)) {
	    trans[i] = val++;
	} else {
	    trans[i] = NOTHING;
	}
    }
}

dbref translate(dbref x)
{
    if(x == NOTHING || x == HOME) {
	return(x);
    } else {
	return(trans[x]);
    }
}

int ok(dbref x)
{
    if(x == NOTHING || x == HOME) {
	return 1;
    } else {
	return trans[x] != NOTHING;
    }
}

void check_bad_exits(dbref x)
{
    dbref e;

    if(Typeof(x) == TYPE_ROOM && !isok(x)) {
	/* mark all exits as excluded */
	DOLIST(e, db[x].exits) {
	    trans[e] = NOTHING;
	}
    }
}

void check_owner(dbref x)
{
    if(ok(x) && !ok(db[x].owner)) {
	db[x].owner = DEFAULT_OWNER;
    }
}

void check_location(dbref x)
{
    dbref loc;
    dbref newloc;

    if(ok(x) && (Typeof(x) == TYPE_THING || Typeof(x) == TYPE_PLAYER)
       && !ok(loc = db[x].location)) {
	/* move it to home or DEFAULT_LOCATION */
	if(ok(db[x].exits)) {
	    newloc = db[x].exits; /* home */
	} else {
	    newloc = DEFAULT_LOCATION;
	}
	db[loc].contents = remove_first(db[loc].contents, x);
	PUSH(x, db[newloc].contents);
	db[x].location = newloc;
    }
}

void check_next(dbref x)
{
    dbref next;

    if(ok(x)) {
	while(!ok(next = db[x].next)) db[x].next = db[next].next;
    }
}

void check_contents(dbref x)
{
    dbref c;

    if(ok(x)) {
	while(!ok(c = db[x].contents)) db[x].contents = db[c].next;
    }
}

/* also updates home */
/* MUST BE CALLED AFTER check_owner! */
void check_exits(dbref x)
{
    dbref e;

    if(ok(x) && !ok(e = db[x].exits)) {
	switch(Typeof(x)) {
	  case TYPE_ROOM:
	    while(!ok(e = db[x].exits)) db[x].exits = db[e].next;
	    break;
	  case TYPE_PLAYER:
	  case TYPE_THING:
	    if(ok(db[db[x].owner].exits)) {
		/* set it to owner's home */
		db[x].exits = db[db[x].owner].exits; /* home */
	    } else {
		/* set it to DEFAULT_LOCATION */
		db[x].exits = DEFAULT_LOCATION; /* home */
	    }
	    break;
	}
    }
}

void do_write(void)
{
    dbref i;
    dbref kludge;

    /* this is braindamaged */
    /* we have to rebuild the translation map */
    /* because part of it may have gotten nuked in check_bad_exits */
    for(i = 0, kludge = 0; i < db_top; i++) {
	if(trans[i] != NOTHING) trans[i] = kludge++;
    }

    for(i = 0; i < db_top; i++) {
	if(ok(i)) {
	    /* translate all object pointers */
	    db[i].location = translate(db[i].location);
	    db[i].contents = translate(db[i].contents);
	    db[i].exits = translate(db[i].exits);
	    db[i].next = translate(db[i].next);
	    db[i].key = translate(db[i].key);
	    db[i].owner = translate(db[i].owner);

	    /* write it out */
	    printf("#%d\n", translate(i));
	    db_write_object(stdout, i);
	}
    }
    puts("***END OF DUMP***");
}

void main(int argc, char **argv)
{
    dbref i;
    int top_in;
    int top_ex;
    char *arg0;

    top_in = 0;
    top_ex = 0;

    /* now parse args */
    arg0 = *argv;
    for(argv++, argc--; argc > 0; argv++, argc--) {
	i = atol(*argv);
	if(i == 0) {
	    if(!strcmp(*argv, "all")) {
		include_all = 1;
	    } else {
		fprintf(stderr, "%s: bogus argument %s\n", arg0, *argv);
	    }
	} else if(i < 0) {
	    excluded[top_ex++] = -i;
	} else {
	    included[top_in++] = i;
	}
    }

    /* Terminate */
    included[top_in++] = NOTHING;
    excluded[top_ex++] = NOTHING;

    /* Load database */
    if(db_read(stdin) < 0) {
	fputs("Database load failed!\n", stderr);
	exit(1);
    } 

    fputs("Done loading database...\n", stderr);

    /* Build translation table */
    build_trans();
    fputs("Done building translation table...\n", stderr);

    /* Scan everything */
    for(i = 0; i < db_top; i++) check_bad_exits(i);
    fputs("Done checking bad exits...\n", stderr);

    for(i = 0; i < db_top; i++) check_owner(i);
    fputs("Done checking owners...\n", stderr);

    for(i = 0; i < db_top; i++) check_location(i);
    fputs("Done checking locations...\n", stderr);

    for(i = 0; i < db_top; i++) check_next(i);
    fputs("Done checking next pointers...\n", stderr);

    for(i = 0; i < db_top; i++) check_contents(i);
    fputs("Done checking contents...\n", stderr);

    for(i = 0; i < db_top; i++) check_exits(i);
    fputs("Done checking homes and exits...\n", stderr);

    do_write();
    fputs("Done.\n", stderr);

    exit(0);
}
