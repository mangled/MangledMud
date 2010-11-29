#include "copyright.h"

#include "db.h"

/* remove the first occurence of what in list headed by first */
dbref remove_first(dbref first, dbref what)
{
    dbref prev;

    /* special case if it's the first one */
    if(first == what) {
	return db[first].next;
    } else {
	/* have to find it */
	DOLIST(prev, first) {
	    if(db[prev].next == what) {
		db[prev].next = db[what].next;
		return first;
	    }
	}
	return first;
    }
}

int member(dbref thing, dbref list)
{
    DOLIST(list, list) {
	if(list == thing) return 1;
    }

    return 0;
}

dbref reverse(dbref list)
{
    dbref newlist;
    dbref rest;

    newlist = NOTHING;
    while(list != NOTHING) {
	rest = db[list].next;
	PUSH(list, newlist);
	list = rest;
    }
    return newlist;
}

const char *getname(dbref loc)
{
    switch(loc) {
      case NOTHING:
	return "***NOTHING***";
      case HOME:
	return "***HOME***";
      default:
	return db[loc].name;
    }
}

