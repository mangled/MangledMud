#include "copyright.h"

/* commands for giving help */

#include "db.h"
#include "config.h"
#include "interface.h"
#include "help.h"

void spit_file(dbref player, const char *filename)
{
    FILE *f;
    char buf[BUFFER_LEN];
    char *p;

    if((f = fopen(filename, "r")) == NULL) {
	sprintf(buf, "Sorry, %s is broken.  Management has been notified.",
		filename);
	notify(player, buf);
	fputs("spit_file:", stderr);
	perror(filename);
    } else {
	while(fgets(buf, sizeof buf, f)) {
	    for(p = buf; *p; p++) if(*p == '\n') {
		*p = '\0';
		break;
	    }
	    notify(player, buf);
	}
	fclose(f);
    }
}

void do_help(dbref player)
{
    spit_file(player, HELP_FILE);
}

void do_news(dbref player)
{
    spit_file(player, NEWS_FILE);
}

