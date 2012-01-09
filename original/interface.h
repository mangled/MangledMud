#include "copyright.h"

#include "db.h"

/* these symbols must be defined by the interface */
extern void notify(dbref player, const char *msg);
extern int shutdown_flag; /* if non-zero, interface should shut down */
extern void emergency_shutdown(void);

/* the following symbols are provided by game.c */

/* max length of command argument to process_command */
#define MAX_COMMAND_LEN 512
#define BUFFER_LEN ((MAX_COMMAND_LEN)*4)
extern void process_command(dbref player, char *command);

extern dbref create_player(const char *name, const char *password);
extern dbref connect_player(const char *name, const char *password);
extern void do_look_around(dbref player);

extern int init_game(const char *infile, const char *outfile);
extern void dump_database(void);
extern void panic(const char *);
