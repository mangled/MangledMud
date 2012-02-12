#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "db.h"

struct object *db = 0;
dbref db_top = 0;

const char *alloc_string(const char *string)
{
    char *s;

    /* NULL, "" -> NULL */
    if(string == 0 || *string == '\0') return 0;

    if((s = (char *) malloc(strlen(string)+1)) == 0) {
	abort();
    }
    strcpy(s, string);
    return s;
}

static void db_grow(dbref newtop)
{
    struct object *newdb;

    if(newtop > db_top) {
	db_top = newtop;
	if(db) {
	    if((newdb = (struct object *)
		realloc((void *) db,
			db_top * sizeof(struct object))) == 0) {
		abort();
	    } 
	    db = newdb;
	} else {
	    /* make the initial one */
	    if((db = (struct object *)
		malloc(db_top * sizeof(struct object))) == 0) {
		abort();
	    }
	}
    }
}

dbref new_object()
{
    dbref newobj;
    struct object *o;

    newobj = db_top;
    db_grow(db_top + 1);

    /* clear it out */
    o = db+newobj;
    o->name = 0;
    o->description = 0;
    o->location = NOTHING;
    o->contents = NOTHING;
    o->exits = NOTHING;
    o->next = NOTHING;
    o->key = NOTHING;
    o->fail_message = 0;
    o->succ_message = 0;
    o->ofail = 0;
    o->osuccess = 0;
    o->owner = NOTHING;
    o->pennies = 0;
    /* flags you must initialize yourself */
    o->password = 0;

    return newobj;
}
	
#define DB_MSGLEN 512

static void putref(FILE *f, dbref ref)
{
    fprintf(f, "%d\n", ref);
}

static void putstring(FILE *f, const char *s)
{
    if(s) {
	fputs(s, f);
    } 
    putc('\n', f);
}
	
int db_write_object(FILE *f, dbref i)
{
    struct object *o;

    o = db + i;
    putstring(f, o->name);
    putstring(f, o->description);
    putref(f, o->location);
    putref(f, o->contents);
    putref(f, o->exits);
    putref(f, o->next);
    putref(f, o->key);
    putstring(f, o->fail_message);
    putstring(f, o->succ_message);
    putstring(f, o->ofail);
    putstring(f, o->osuccess);
    putref(f, o->owner);
    putref(f, o->pennies);
    putref(f, o->flags);
    putstring(f, o->password);

    return 0;
}

dbref db_write(FILE *f)
{
    dbref i;

    for(i = 0; i < db_top; i++) {
	fprintf(f, "#%d\n", i);
	db_write_object(f, i);
    }
    fputs("***END OF DUMP***\n", f);
    fflush(f);
    return(db_top);
}

dbref parse_dbref(const char *s)
{
    const char *p;
    long x;

    x = atol(s);
    if(x > 0) {
	return x;
    } else if(x == 0) {
	/* check for 0 */
	for(p = s; *p; p++) {
	    if(*p == '0') return 0;
	    if(!isspace(*p)) break;
	}
    }

    /* else x < 0 or s != 0 */
    return NOTHING;
}
	    
static dbref getref(FILE *f)
{
    static char buf[DB_MSGLEN];

    char* s = fgets(buf, sizeof(buf), f);
    (void) s;
    return(atol(buf));
}

static const char *getstring(FILE *f)
{
    static char buf[DB_MSGLEN];
    char *p;

    char* s = fgets(buf, sizeof(buf), f);
    (void) s;

    for(p = buf; *p; p++) {
	if(*p == '\n') {
	    *p = '\0';
	    break;
	}
    }

    if(!*buf) {
	return(0);
    } else {
	return(alloc_string(buf));
    }
}

void db_free()
{
    dbref i;
    struct object *o;

    if(db) {
	for(i = 0; i < db_top; i++) {
	    o = &db[i];
	    if(o->name) free((void*) o->name);
	    if(o->description) free((void*) o->description);
	    if(o->succ_message) free((void*) o->succ_message);
	    if(o->fail_message) free((void*) o->fail_message);
	    if(o->ofail) free((void*) o->ofail);
	    if(o->osuccess) free((void*) o->osuccess);
	    if(o->password) free((void*) o->password);
	}
	free(db);
	db = 0;
	db_top = 0;
    }
}

dbref db_read(FILE *f)
{
    dbref i;
    struct object *o;
    const char *end;

    db_free();
    for(i = 0;; i++) {
	switch(getc(f)) {
	  case '#':
	    /* another entry, yawn */
	    if(i != getref(f)) {
		/* we blew it */
		return -1;
	    }
	    /* make space */
	    db_grow(i+1);
	    
	    /* read it in */
	    o = db+i;
	    o->name = getstring(f);
	    o->description = getstring(f);
	    o->location = getref(f);
	    o->contents = getref(f);
	    o->exits = getref(f);
	    o->next = getref(f);
	    o->key = getref(f);
	    o->fail_message = getstring(f);
	    o->succ_message = getstring(f);
	    o->ofail = getstring(f);
	    o->osuccess = getstring(f);
	    o->owner = getref(f);
	    o->pennies = getref(f);
	    o->flags = getref(f);
	    o->password = getstring(f);
	    break;
	  case '*':
	    end = getstring(f);
	    if(strcmp(end, "**END OF DUMP***")) {
		free((void*) end);
		return -1;
	    } else {
		free((void*) end);
		return db_top;
	    }
	  default:
	    return -1;
	    break;
	}
    }
}
		
