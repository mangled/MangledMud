#include "copyright.h"
#include "db.h"

/* these symbols must be defined by the interface */
extern void notify(dbref player, const char *msg);
extern int shutdown_flag; /* if non-zero, interface should shut down */
extern void emergency_shutdown(void);
extern void process_command(dbref player, char *command);

/* max length of command argument to process_command */
#define MAX_COMMAND_LEN 512
#define BUFFER_LEN ((MAX_COMMAND_LEN)*4)
