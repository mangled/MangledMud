#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>

#include "config.h"
#include "interface.h"

/* declarations */
static const char *dumpfile = 0;
static int epoch = 0;
static int alarm_triggered = 0;
static int alarm_block = 0;

static void fork_and_dump(void);
void dump_database(void);

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

void do_dump(dbref player)
{
    //if (Wizard(player)) {
		alarm_triggered = 1;
		notify(player, "Dumping...");
    //} else {
	//	notify(player, "Sorry, you are in a no dumping zone.");
    //}
}

void do_shutdown(dbref player)
{
    //if (Wizard(player)) {
		fprintf(stderr, "SHUTDOWN: by (%d)\n", player);
		fflush(stderr);
		shutdown_flag = 1;
		notify(player, "Shutdown...");
    //} else {
	//	notify(player, "Your delusions of grandeur have been duly noted.");
    //}
}

static void alarm_handler(int sig)
{
    (void) sig;
    alarm_triggered = 1;
    if (!alarm_block) {
        fork_and_dump();
    }
    return;
}

static void dump_database_internal()
{
	printf("dump_database_internal\n");
}

void panic(const char *message)
{
    char panicfile[2048];
    FILE *f;
    int i;

    fprintf(stderr, "PANIC: %s\n", message);

    /* turn off signals */
    for(i = 0; i < NSIG; i++) {
		signal(i, SIG_IGN);
    }

    /* shut down interface */
    emergency_shutdown();

    /* dump panic file */
    sprintf(panicfile, "%s.PANIC", dumpfile);
    if((f = fopen(panicfile, "w")) == NULL) {
		perror("CANNOT OPEN PANIC FILE, YOU LOSE:");
		_exit(135);
    } else {
		fprintf(stderr, "DUMPING: %s\n", panicfile);
		fclose(f);
		fprintf(stderr, "DUMPING: %s (done)\n", panicfile);
		_exit(136);
    }
}

void dump_database()
{
    epoch++;

    fprintf(stderr, "DUMPING: %s.#%d#\n", dumpfile, epoch);
    dump_database_internal();
    fprintf(stderr, "DUMPING: %s.#%d# (done)\n", dumpfile, epoch);
}

static void fork_and_dump()
{
    int child;

    epoch++;

    fprintf(stderr, "CHECKPOINTING: %s.#%d#\n", dumpfile, epoch);
    child = fork();
    if(child == 0) {
		/* in the child */
		close(0);		/* get that file descriptor back */
		dump_database_internal();
		_exit(0);		/* !!! */
    } else if(child < 0) {
		perror("fork_and_dump: fork()");
    }
	
    /* in the parent */
    /* reset alarm */
    alarm_triggered = 0;
    alarm(DUMP_INTERVAL);
}

static void reaper(int sig)
{
    (void) sig;
    union wait stat;

    while(wait3(&stat, WNOHANG, 0) > 0);
    return;
}

int init_game(const char *infile, const char *outfile)
{
   FILE *f;

   if((f = fopen(infile, "r")) == NULL) return -1;
   
   /* ok, read it in */
   fprintf(stderr, "LOADING: %s\n", infile);
   fprintf(stderr, "LOADING: %s (done)\n", infile);

   /* everything ok */
   fclose(f);

   /* initialize random number generator */
   srandom(getpid());

   /* set up dumper */
   if(dumpfile) free((void*) dumpfile);
   dumpfile = alloc_string(outfile);
   signal(SIGALRM, alarm_handler);
   signal(SIGHUP, alarm_handler);
   signal(SIGCHLD, reaper);
   alarm_triggered = 0;
   alarm(DUMP_INTERVAL);
   
   return 0;
}

/* use this only in process_command */
#define Matched(string) { if(!string_prefix((string), command)) goto bad; }

void process_command(dbref player, char *command)
{
	printf("process_command %d %s\n", player, command);

    char *arg1;
    char *arg2;
    char *q;			/* utility */
    char *p;			/* utility */

    if(command == 0) abort();

    /* robustify player */
    if(player < 0) {
		fprintf(stderr, "process_command: bad player %d\n", player);
		return;
    }

    /* eat leading whitespace */
    while(*command && isspace(*command)) command++;

    /* eat extra white space */
    q = p = command;
    while(*p) {
		/* scan over word */
		while(*p && !isspace(*p)) *q++ = *p++;
		/* smash spaces */
		while(*p && isspace(*++p));
		if(*p) *q++ = ' '; /* add a space to separate next word */
    }
    /* terminate */
    *q = '\0';

    /* block dump to prevent db inconsistencies from showing up */
    alarm_block = 1;

	/* parse arguments */

	/* find arg1 */
	/* move over command word */
	for(arg1 = command; *arg1 && !isspace(*arg1); arg1++);
	/* truncate command */
	if(*arg1) *arg1++ = '\0';

	/* move over spaces */
	while(*arg1 && isspace(*arg1)) arg1++;

	/* find end of arg1, start of arg2 */
	for(arg2 = arg1; *arg2 && *arg2 != '='; arg2++);

	/* truncate arg1 */
	for(p = arg2 - 1; p >= arg1 && isspace(*p); p--) *p = '\0';

	/* go past '=' if present */
	if(*arg2) *arg2++ = '\0';
	while(*arg2 && isspace(*arg2)) arg2++;

	switch(command[0]) {
	  case '@':
	    switch(command[1]) {
			case 'd':
			case 'D':
				/* describe, dig, or dump */
				switch(command[2]) {
				  case 'u':
				  case 'U':
					if (strcmp(command, "@dump") == 0) {
						do_dump(player);
					}
					break;
				}
				break;
			case 'f':
				/* fail, find, or force */
				switch(command[2]) {
		#ifdef DO_FLUSH
				  case 'l':
				  case 'L':
					if (strcmp(command, "@flush") == 0) {
						do_flush(player);
					}
					break;
		#endif				/* DO_FLUSH */
				}
				break;
			case 's':
			case 'S':
				/* set, shutdown, success */
				switch(command[2]) {
				  case 'h':
					if (strcmp(command, "@shutdown") == 0) {
						do_shutdown(player);
					}
					break;
				}
				break;
			default:
				break;
		}
    }
    /* unblock alarms */
    alarm_block = 0;
    if(alarm_triggered) {
		fork_and_dump();
    }
}

#undef Matched
