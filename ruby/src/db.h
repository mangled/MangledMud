#include "copyright.h"

#ifndef __DB_H
#define __DB_H
#include <stdio.h>

typedef int dbref;		/* offset into db */

#define TYPE_ROOM 	0x0
#define TYPE_THING 	0x1
#define TYPE_EXIT 	0x2
#define TYPE_PLAYER 	0x3
#define NOTYPE		0x7	/* no particular type */
#define TYPE_MASK 	0x7	/* room for expansion */
#define ANTILOCK	0x8	/* if present, makes key cause failure */
#define WIZARD		0x10	/* gets automatic control */
#define LINK_OK		0x20	/* anybody can link to this room */
#define DARK		0x40	/* contents of room are not printed */
#define TEMPLE		0x80	/* objects dropped in this room go home */
#define STICKY		0x100	/* this object goes home when dropped */

#ifdef RESTRICTED_BUILDING
#define BUILDER		0x200	/* this player can use construction commands */
#endif /* RESTRICTED_BUILDING */

typedef int object_flag_type;

#define Typeof(x) (db[(x)].flags & TYPE_MASK)
#define Wizard(x) ((db[(x)].flags & WIZARD) != 0)
#define Dark(x) ((db[(x)].flags & DARK) != 0)

#ifdef RESTRICTED_BUILDING
#define Builder(x) ((db[(x)].flags & (WIZARD|BUILDER)) != 0)
#endif /* RESTRICTED_BUILDING */

/* special dbref's */
#define NOTHING (-1)		/* null dbref */
#define AMBIGUOUS (-2)		/* multiple possibilities, for matchers */
#define HOME (-3)		/* virtual room, represents mover's home */

struct object {
    const char *name;			
    const char *description;		
    dbref location;		/* pointer to container */
				/* for exits, pointer to destination */
    dbref contents;		/* pointer to first item */
    dbref exits;		/* pointer to first exit for rooms */
    				/* pointer to home for things and players */
    dbref next;			/* pointer to next in contents/exits chain */

    /* the following are used for pickups for things, entry for exits */
    dbref key;			/* if not NOTHING, must have this to do op */
    const char *fail_message;		/* what you see if op fails */
    const char *succ_message;		/* what you see if op succeeds */
    /* other messages get your name prepended, so if your name is "Foo", */
    /* and osuccess = "disappears in a blast of gamma radiation." */
    /* then others see "Foo disappears in a blast of gamma radiation." */
    /* (At some point I may put in Maven-style %-substitutions.) */
    const char *ofail;		/* what others see if op fails */
    const char *osuccess;	/* what others see if op succeeds */

    dbref owner;		/* who controls this object */
    int pennies;		/* number of pennies object contains */
    object_flag_type flags;
    const char *password;	/* password for players */
};

extern struct object *db;
extern dbref db_top;

extern const char *alloc_string(const char *s);

extern dbref new_object();	/* return a new object */

extern int db_write_object(FILE *, dbref); /* write one object to file */

extern dbref db_write(FILE *f);	/* write db to file, return # of objects */

extern dbref db_read(FILE *f);	/* read db from file, return # of objects */
				/* Warning: destroys existing db contents! */

extern void db_free();

extern dbref parse_dbref(const char *);	/* parse a dbref */

#define DOLIST(var, first) \
  for((var) = (first); (var) != NOTHING; (var) = db[(var)].next)
#define PUSH(thing, locative) \
    ((db[(thing)].next = (locative)), (locative) = (thing))
#define getloc(thing) (db[thing].location)

/*
  Usage guidelines:

  To refer to objects use db[object_ref].  Pointers to objects may 
  become invalid after a call to new_object().

  The programmer is responsible for managing storage for string
  components of entries; db_read will produce malloc'd strings.  The
  alloc_string routine is provided for generating malloc'd strings
  duplicates of other strings.  Note that db_free and db_read will
  attempt to free any non-NULL string that exists in db when they are
  invoked.  
*/
#endif /* __DB_H */
