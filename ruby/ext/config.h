#include "copyright.h"

/* room number of player start location */
#define PLAYER_START 0

/* minimum cost to create various things */
#define OBJECT_COST 10
#define EXIT_COST 1
#define LINK_COST 1
#define ROOM_COST 10

/* cost to do a scan */
#define LOOKUP_COST 1

/* magic cookies */
#define NOT_TOKEN '!'
#define LOOKUP_TOKEN '*'
#define NUMBER_TOKEN '#'

/* magic command cookies */
#define SAY_TOKEN '"'
#define POSE_TOKEN ':'

/* amount of object endowment, based on cost */
#define MAX_OBJECT_ENDOWMENT 100
#define OBJECT_ENDOWMENT(cost) (((cost)-5)/5)

/* amount at which temple stops being so profitable */
#define MAX_PENNIES 10000

/* penny generation parameters */
#define PENNY_RATE 10		/* 1/chance of getting a penny per room */

/* costs of kill command */
#define KILL_BASE_COST 100	/* prob = expenditure/KILL_BASE_COST */
#define KILL_MIN_COST 10
#define KILL_BONUS 50		/* paid to victim */

/* delimeter for lists of exit aliases */
#define EXIT_DELIMITER ';'

/* timing stuff */
#define DUMP_INTERVAL 3600	/* seconds between dumps */
#define COMMAND_TIME_MSEC 250	/* time slice length in milliseconds */
#define COMMAND_BURST_SIZE 250	/* commands allowed per user in a burst */
#define COMMANDS_PER_TIME 1	/* commands per time slice after burst */

/* maximum amount of queued output */
#define MAX_OUTPUT 16384

#define TINYPORT 4201
#define WELCOME_MESSAGE "Welcome to TinyMUD\nTo connect to your existing character, enter \"connect name password\"\nTo create a new character, enter \"create name password\"\nUse the news command to get up-to-date news on program changes.\n\nYou can disconnect using the QUIT command, which must be capitalized as shown.\n\nUse the WHO command to find out who is currently active.\n\n"

#define LEAVE_MESSAGE "\n***Disconnected***\n"

#define QUIT_COMMAND "QUIT"
#define WHO_COMMAND "WHO"
#define PREFIX_COMMAND "OUTPUTPREFIX"
#define SUFFIX_COMMAND "OUTPUTSUFFIX"

#define HELP_FILE "help.txt"

#define NEWS_FILE "news.txt"
