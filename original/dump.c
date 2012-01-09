#include "copyright.h"

#include <stdlib.h>

#include "db.h"
#include "externs.h"

int main(int argc, char **argv)
{
    struct object *o;
    dbref owner;
    dbref thing;

    if(argc < 1) {
	fprintf(stderr, "Usage: %s [owner]\n", *argv);
	exit(1);
    }
    
    if(argc >= 2) {
	owner = atol(argv[1]);
    } else {
	owner = NOTHING;
    }

    if(db_read(stdin) < 0) {
	fprintf(stderr, "%s: bad input\n", argv[0]);
	exit(5);
    }

    for(o = db; o < db+db_top; o++) {
	/* don't show exits separately */
	if((o->flags & TYPE_MASK) == TYPE_EXIT) continue;

	/* don't show it if it isn't owned by the right player */
	if(owner != NOTHING && o->owner != owner) continue;

	printf("#%d: %s [%s] at %s(%d) Pennies: %d Type: ",
	       (int)(o - db), o->name, db[o->owner].name,
	       getname(o->location),
	       o->location,
	       o->pennies);
	switch(o->flags & TYPE_MASK) {
	  case TYPE_ROOM:
	    printf("Room");
	    break;
	  case TYPE_EXIT:
	    printf("Exit");
	    break;
	  case TYPE_THING:
	    printf("Thing");
	    break;
	  case TYPE_PLAYER:
	    printf("Player");
	    break;
	  default:
	    printf("***UNKNOWN TYPE***");
	    break;
	}

	/* handle flags */
	putchar(' ');
	if(o->flags & ~TYPE_MASK) {
	    printf("Flags: ");
	    if(o->flags & LINK_OK) printf("LINK_OK ");
	    if(o->flags & DARK) printf("DARK ");
	    if(o->flags & STICKY) printf("STICKY ");
	    if(o->flags & WIZARD) printf("WIZARD ");
	    if(o->flags & TEMPLE) printf("TEMPLE ");
#ifdef RESTRICTED_BUILDING
	    if(o->flags & BUILDER) printf("BUILDER ");
#endif /* RESTRICTED_BUILDING */
	}
	putchar('\n');
	       
	if(o->key != NOTHING) printf("KEY: %c%s\n",
				     o->flags & ANTILOCK ? '!' : ' ',
				     getname(o->key));
	if(o->description) {
	    puts("Description:");
	    puts(o->description);
	}
	if(o->succ_message) {
	    puts("Success Message:");
	    puts(o->succ_message);
	}
	if(o->fail_message) {
	    puts("Fail Message:");
	    puts(o->fail_message);
	}
	if(o->ofail) {
	    puts("Other Fail Message:");
	    puts(o->ofail);
	}
	if(o->osuccess) {
	    puts("Other Success Message:");
	    puts(o->osuccess);
	}
	if(o->contents != NOTHING) {
	    puts("Contents:");
	    DOLIST(thing, o->contents) {
		/* dump thing description */
		printf(" %s(%d)\n", db[thing].name, thing);
	    }
	}
	if(o->exits != NOTHING) {
	    if((o->flags & TYPE_MASK) == TYPE_ROOM) {
		puts("Exits:");
		DOLIST(thing, o->exits) {
		    printf(" %s", getname(thing));
		    if(db[thing].key != NOTHING) {
			printf(" KEY: %c%s(%d)",
			       db[thing].flags & ANTILOCK ? '!' : ' ',
			       getname(db[thing].key),
			       db[thing].key);
		    }
		    if(db[thing].location != NOTHING) {
			printf(" => %s(%d)\n",
			       getname(db[thing].location),
			       db[thing].location);
		    } else {
			puts(" ***OPEN***");
		    }
		}
	    } else {
		printf("Home: %s(%d)\n", getname(o->exits), o->exits);
	    }
	}
	putchar('\n');
    }

    exit(0);
}
