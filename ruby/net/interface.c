#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/time.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/errno.h>
#include <ctype.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <time.h>

#include "db.h"
#include "interface.h"
#include "config.h"

extern int	errno;
int	shutdown_flag = 0;

static const char *connect_fail = "Either that player does not exist, or has a different password.\n";
static const char *create_fail = "Either there is already a player with that name, or that name is illegal.\n";
static const char *flushed_message = "<Output Flushed>\n";
static const char *shutdown_message = "Going down - Bye\n";

struct text_block {
	int			nchars;
	struct text_block	*nxt;
	char			*start;
	char			*buf;
};

struct text_queue {
    struct text_block *head;
    struct text_block **tail;
};

struct descriptor_data {
        int descriptor;
	int connected;
	dbref player;
	char *output_prefix;
	char *output_suffix;
	int output_size;
	struct text_queue output;
	struct text_queue input;
	char *raw_input;
	char *raw_input_at;
	long last_time;
	int quota;
	struct descriptor_data *next;
	struct descriptor_data **prev;
} *descriptor_list = 0;

static int sock;
static int ndescriptors = 0;

void process_commands(void);
void shovechars(int port);
void shutdownsock(struct descriptor_data *d);
struct descriptor_data *initializesock(int s);
void make_nonblocking(int s);
void freeqs(struct descriptor_data *d);
void welcome_user(struct descriptor_data *d);
void check_connect(struct descriptor_data *d, const char *msg);
void close_sockets();
const char *addrout (long);
void dump_users(struct descriptor_data *d);
void set_signals();
struct descriptor_data *new_connection(int sock);
void parse_connect (const char *msg, char *command, char *user, char *pass);
void set_userstring (char **userstring, const char *command);
int do_command (struct descriptor_data *d, char *command);
char *strsave (const char *s);
int make_socket(int);
int queue_string(struct descriptor_data *, const char *);
int queue_write(struct descriptor_data *, const char *, int);
int process_output(struct descriptor_data *d);
int process_input(struct descriptor_data *d);
void bailout(int);
void dump_status(int);

#define MALLOC(result, type, number) do {			\
	if (!((result) = (type *) malloc ((number) * sizeof (type))))	\
		panic("Out of memory");				\
	} while (0)

#define FREE(x) (free(x))

int main(int argc, char **argv)
{
    if (argc < 3) {
	fprintf (stderr, "Usage: %s infile dumpfile [port]\n", *argv);
	exit (1);
    }
    if (init_game (argv[1], argv[2]) < 0) {
	fprintf (stderr, "Couldn't load %s!\n", argv[1]);
	exit (2);
    }
    set_signals ();
    /* go do it */
    shovechars (argc >= 4 ? atoi (argv[3]) : TINYPORT);
    close_sockets ();
    dump_database ();
    exit (0);
}

void set_signals()
{
    /* we don't care about SIGPIPE, we notice it in select() and write() */
    signal (SIGPIPE, SIG_IGN);

    /* standard termination signals */
    signal (SIGINT, bailout);
    signal (SIGTERM, bailout);

    /* catch these because we might as well */
    signal (SIGQUIT, bailout);
    signal (SIGILL, bailout);
    signal (SIGTRAP, bailout);
    signal (SIGIOT, bailout);
#if !defined linux
    signal (SIGEMT, bailout);
#endif
    signal (SIGFPE, bailout);
    signal (SIGBUS, bailout);
    signal (SIGSEGV, bailout);
    signal (SIGSYS, bailout);
    signal (SIGTERM, bailout);
    signal (SIGXCPU, bailout);
    signal (SIGXFSZ, bailout);
    signal (SIGVTALRM, bailout);
    signal (SIGUSR2, bailout);

    /* status dumper (predates "WHO" command) */
    signal (SIGUSR1, dump_status);
}

void notify(dbref player, const char *msg)
{
    struct descriptor_data *d;

    for (d = descriptor_list; d; d = d->next) {
	if (d->connected && d->player == player) {
	    queue_string (d, msg);
	    queue_write (d, "\n", 1);
	}
    }
}

struct timeval timeval_sub(struct timeval now, struct timeval then)
{
    now.tv_sec -= then.tv_sec;
    now.tv_usec -= then.tv_usec;
    if (now.tv_usec < 0) {
	now.tv_usec += 1000000;
	now.tv_sec--;
    }
    return now;
}

int msec_diff(struct timeval now, struct timeval then)
{
    return ((now.tv_sec - then.tv_sec) * 1000
	    + (now.tv_usec - then.tv_usec) / 1000);
}

struct timeval msec_add(struct timeval t, int x)
{
    t.tv_sec += x / 1000;
    t.tv_usec += (x % 1000) * 1000;
    if (t.tv_usec >= 1000000) {
	t.tv_sec += t.tv_usec / 1000000;
	t.tv_usec = t.tv_usec % 1000000;
    }
    return t;
}

struct timeval update_quotas(struct timeval last, struct timeval current)
{
    int nslices;
    struct descriptor_data *d;

    nslices = msec_diff (current, last) / COMMAND_TIME_MSEC;

    if (nslices > 0) {
	for (d = descriptor_list; d; d = d -> next) {
	    d -> quota += COMMANDS_PER_TIME * nslices;
	    if (d -> quota > COMMAND_BURST_SIZE)
		d -> quota = COMMAND_BURST_SIZE;
	}
    }
    return msec_add (last, nslices * COMMAND_TIME_MSEC);
}

void shovechars(int port)
{
    fd_set input_set, output_set;
    long now;
    struct timeval last_slice, current_time;
    struct timeval next_slice;
    struct timeval timeout, slice_timeout;
    int maxd;
    struct descriptor_data *d, *dnext;
    struct descriptor_data *newd;
    int avail_descriptors;

    sock = make_socket (port);
    maxd = sock+1;
    gettimeofday(&last_slice, (struct timezone *) 0);

    avail_descriptors = getdtablesize() - 4;
    
    while (shutdown_flag == 0) {
	gettimeofday(&current_time, (struct timezone *) 0);
	last_slice = update_quotas (last_slice, current_time);

	process_commands();

	if (shutdown_flag)
	    break;
	timeout.tv_sec = 1000;
	timeout.tv_usec = 0;
	next_slice = msec_add (last_slice, COMMAND_TIME_MSEC);
	slice_timeout = timeval_sub (next_slice, current_time);
	
	FD_ZERO (&input_set);
	FD_ZERO (&output_set);
	if (ndescriptors < avail_descriptors)
	    FD_SET (sock, &input_set);
	for (d = descriptor_list; d; d=d->next) {
	    if (d->input.head)
		timeout = slice_timeout;
	    else
		FD_SET (d->descriptor, &input_set);
	    if (d->output.head)
		FD_SET (d->descriptor, &output_set);
	}

	if (select (maxd, &input_set, &output_set,
		    (fd_set *) 0, &timeout) < 0) {
	    if (errno != EINTR) {
		perror ("select");
		return;
	    }
	} else {
	    (void) time (&now);
	    if (FD_ISSET (sock, &input_set)) {
		if (!(newd = new_connection (sock))) {
		    if (errno != EINTR && errno != EMFILE) {
			perror ("new_connection");
			return;
		    }
		} else {
		if (newd->descriptor >= maxd)
		    maxd = newd->descriptor + 1;
		}
	    }
	    for (d = descriptor_list; d; d = dnext) {
		dnext = d->next;
		if (FD_ISSET (d->descriptor, &input_set)) {
			d->last_time = now;
			if (!process_input (d)) {
			    shutdownsock (d);
			    continue;
			}
		}
		if (FD_ISSET (d->descriptor, &output_set)) {
		    if (!process_output (d)) {
			shutdownsock (d);
		    }
		}
	    }
	}
    }
}

struct descriptor_data *new_connection(int sock)
{
    int newsock;
    struct sockaddr_in addr;
    socklen_t addr_len;

    addr_len = sizeof (addr);
    newsock = accept (sock, (struct sockaddr *) &addr, &addr_len);
    if (newsock < 0) {
	return 0;
    } else {
	fprintf (stderr, "ACCEPT from %s(%d) on descriptor %d\n", addrout (ntohl (addr.sin_addr.s_addr)), ntohs (addr.sin_port), newsock);
	return initializesock (newsock);
    }
}

const char *addrout(long a)
{
    static char buf[1024];

    sprintf (buf, "%d.%d.%d.%d", (int)((a >> 24) & 0xff), (int)((a >> 16) & 0xff),
	     (int)((a >> 8) & 0xff), (int)(a & 0xff));
    return buf;
}

void clearstrings(struct descriptor_data *d)
{
    if (d->output_prefix) {
	FREE (d->output_prefix);
	d->output_prefix = 0;
    }
    if (d->output_suffix) {
	FREE (d->output_suffix);
	d->output_suffix = 0;
    }
}

void shutdownsock(struct descriptor_data *d)
{
    if (d->connected) {
	fprintf (stderr, "DISCONNECT descriptor %d player %s(%d)\n",
		d->descriptor, db[d->player].name, d->player);
    } else {
	fprintf (stderr, "DISCONNECT descriptor %d never connected\n",
		d->descriptor);
    }
    clearstrings (d);
    shutdown (d->descriptor, 2);
    close (d->descriptor);
    freeqs (d);
    *d->prev = d->next;
    if (d->next)
        d->next->prev = d->prev;
    FREE (d);
    ndescriptors--;
}

struct descriptor_data *initializesock(int s)
{
    struct descriptor_data *d;

    ndescriptors++;
    MALLOC(d, struct descriptor_data, 1);
    d->descriptor = s;
    d->connected = 0;
    make_nonblocking (s);
    d->output_prefix = 0;
    d->output_suffix = 0;
    d->output_size = 0;
    d->output.head = 0;
    d->output.tail = &d->output.head;
    d->input.head = 0;
    d->input.tail = &d->input.head;
    d->raw_input = 0;
    d->raw_input_at = 0;
    d->quota = COMMAND_BURST_SIZE;
    d->last_time = 0;
    if (descriptor_list)
        descriptor_list->prev = &d->next;
    d->next = descriptor_list;
    d->prev = &descriptor_list;
    descriptor_list = d;
    
    welcome_user (d);
    return d;
}

int make_socket(int port)
{
    int s;
    struct sockaddr_in server;
    int opt;

    s = socket (AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
	perror ("creating stream socket");
	exit (3);
    }
    opt = 1;
    if (setsockopt (s, SOL_SOCKET, SO_REUSEADDR,
		    (char *) &opt, sizeof (opt)) < 0) {
	perror ("setsockopt");
	exit (1);
    }
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_port = htons (port);
    if (bind (s, (struct sockaddr *) & server, sizeof (server))) {
	perror ("binding stream socket");
	close (s);
	exit (4);
    }
    listen (s, 5);
    return s;
}

struct text_block *make_text_block(const char *s, int n)
{
	struct text_block *p;

	MALLOC(p, struct text_block, 1);
	MALLOC(p->buf, char, n);
	bcopy (s, p->buf, n);
	p->nchars = n;
	p->start = p->buf;
	p->nxt = 0;
	return p;
}

void free_text_block (struct text_block *t)
{
	FREE (t->buf);
	FREE ((char *) t);
}

void add_to_queue(struct text_queue *q, const char *b, int n)
{
    struct text_block *p;

    if (n == 0) return;

    p = make_text_block (b, n);
    p->nxt = 0;
    *q->tail = p;
    q->tail = &p->nxt;
}

int flush_queue(struct text_queue *q, int n)
{
        struct text_block *p;
	int really_flushed = 0;
	
	n += strlen(flushed_message);

	while (n > 0 && (p = q->head)) {
	    n -= p->nchars;
	    really_flushed += p->nchars;
	    q->head = p->nxt;
	    free_text_block (p);
	}
	p = make_text_block(flushed_message, strlen(flushed_message));
	p->nxt = q->head;
	q->head = p;
	if (!p->nxt)
	    q->tail = &p->nxt;
	really_flushed -= p->nchars;
	return really_flushed;
}

int queue_write(struct descriptor_data *d, const char *b, int n)
{
    int space;

    space = MAX_OUTPUT - d->output_size - n;
    if (space < 0)
        d->output_size -= flush_queue(&d->output, -space);
    add_to_queue (&d->output, b, n);
    d->output_size += n;
    return n;
}

int queue_string(struct descriptor_data *d, const char *s)
{
    return queue_write (d, s, strlen (s));
}

int process_output(struct descriptor_data *d)
{
    struct text_block **qp, *cur;
    int cnt;

    for (qp = &d->output.head; (cur = *qp);) {
	cnt = write (d->descriptor, cur -> start, cur -> nchars);
	if (cnt < 0) {
	    if (errno == EWOULDBLOCK)
		return 1;
	    return 0;
	}
	d->output_size -= cnt;
	if (cnt == cur -> nchars) {
	    if (!cur -> nxt)
		d->output.tail = qp;
	    *qp = cur -> nxt;
	    free_text_block (cur);
	    continue;		/* do not adv ptr */
	}
	cur -> nchars -= cnt;
	cur -> start += cnt;
	break;
    }
    return 1;
}

void make_nonblocking(int s)
{
    if (fcntl (s, F_SETFL, FNDELAY) == -1) {
	perror ("make_nonblocking: fcntl");
	panic ("FNDELAY fcntl failed");
    }
}

void freeqs(struct descriptor_data *d)
{
    struct text_block *cur, *next;

    cur = d->output.head;
    while (cur) {
	next = cur -> nxt;
	free_text_block (cur);
	cur = next;
    }
    d->output.head = 0;
    d->output.tail = &d->output.head;

    cur = d->input.head;
    while (cur) {
	next = cur -> nxt;
	free_text_block (cur);
	cur = next;
    }
    d->input.head = 0;
    d->input.tail = &d->input.head;

    if (d->raw_input)
        FREE (d->raw_input);
    d->raw_input = 0;
    d->raw_input_at = 0;
}

void welcome_user(struct descriptor_data *d)
{
    queue_string (d, WELCOME_MESSAGE);
}

void goodbye_user(struct descriptor_data *d)
{
    ssize_t bytes_written = write (d->descriptor, LEAVE_MESSAGE, strlen (LEAVE_MESSAGE));
    (void) bytes_written;
}

char *strsave (const char *s)
{
    char *p;

    MALLOC (p, char, strlen(s) + 1);

    if (p)
	strcpy (p, s);
    return p;
}

void save_command (struct descriptor_data *d, const char *command)
{
    add_to_queue (&d->input, command, strlen(command)+1);
}

int process_input (struct descriptor_data *d)
{
    char buf[1024];
    int got;
    char *p, *pend, *q, *qend;

    got = read (d->descriptor, buf, sizeof buf);
    if (got <= 0)
	return 0;
    if (!d->raw_input) {
	MALLOC(d->raw_input,char,MAX_COMMAND_LEN);
	d->raw_input_at = d->raw_input;
    }
    p = d->raw_input_at;
    pend = d->raw_input + MAX_COMMAND_LEN - 1;
    for (q=buf, qend = buf + got; q < qend; q++) {
	if (*q == '\n') {
	    *p = '\0';
	    if (p > d->raw_input)
		save_command (d, d->raw_input);
	    p = d->raw_input;
	} else if (p < pend && isascii (*q) && isprint (*q)) {
	    *p++ = *q;
	}
    }
    if (p > d->raw_input) {
	d->raw_input_at = p;
    } else {
	FREE (d->raw_input);
	d->raw_input = 0;
	d->raw_input_at = 0;
    }
    return 1;
}

void set_userstring (char **userstring, const char *command)
{
    if (*userstring) {
	FREE (*userstring);
	*userstring = 0;
    }
    while (*command && isascii (*command) && isspace (*command))
	command++;
    if (*command)
	*userstring = strsave (command);
}

void process_commands()
{
    int nprocessed;
    struct descriptor_data *d, *dnext;
    struct text_block *t;

    do {
	nprocessed = 0;
	for (d = descriptor_list; d; d = dnext) {
	    dnext = d->next;
	    if (d -> quota > 0 && (t = d -> input.head)) {
		d -> quota--;
		nprocessed++;
		if (!do_command (d, t -> start)) {
		    shutdownsock (d);
		} else {
		    d -> input.head = t -> nxt;
		    if (!d -> input.head)
			d -> input.tail = &d -> input.head;
		    free_text_block (t);
		}
	    }
	}
    } while (nprocessed > 0);
}

int do_command (struct descriptor_data *d, char *command)
{
    if (!strcmp (command, QUIT_COMMAND)) {
	goodbye_user (d);
	return 0;
    } else if (!strcmp (command, WHO_COMMAND)) {
	dump_users (d);
    } else if (!strncmp (command, PREFIX_COMMAND, strlen (PREFIX_COMMAND))) {
	set_userstring (&d->output_prefix, command+strlen(PREFIX_COMMAND));
    } else if (!strncmp (command, SUFFIX_COMMAND, strlen (SUFFIX_COMMAND))) {
	set_userstring (&d->output_suffix, command+strlen(SUFFIX_COMMAND));
    } else {
	if (d->connected) {
	    if (d->output_prefix) {
		queue_string (d, d->output_prefix);
		queue_write (d, "\n", 1);
	    }
	    process_command (d->player, command);
	    if (d->output_suffix) {
		queue_string (d, d->output_suffix);
		queue_write (d, "\n", 1);
	    }
	} else {
	    check_connect (d, command);
	}
    }
    return 1;
}

void check_connect (struct descriptor_data *d, const char *msg)
{
    char command[MAX_COMMAND_LEN];
    char user[MAX_COMMAND_LEN];
    char password[MAX_COMMAND_LEN];
    dbref player;

    parse_connect (msg, command, user, password);

    if (!strncmp (command, "co", 2)) {
	player = connect_player (user, password);
	if (player == NOTHING) {
	    queue_string (d, connect_fail);
	    fprintf (stderr, "FAILED CONNECT %s on descriptor %d\n",
		     user, d->descriptor);
	} else {
	    fprintf (stderr, "CONNECTED %s(%d) on descriptor %d\n",
		     db[player].name, player, d->descriptor);
	    d->connected = 1;
	    d->player = player;
		notify(player, "do_look_around()");
	}
    } else if (!strncmp (command, "cr", 2)) {
	player = create_player (user, password);
	if (player == NOTHING) {
	    queue_string (d, create_fail);
	    fprintf (stderr, "FAILED CREATE %s on descriptor %d\n",
		     user, d->descriptor);
	} else {
	    fprintf (stderr, "CREATED %s(%d) on descriptor %d\n",
		     db[player].name, player, d->descriptor);
	    d->connected = 1;
	    d->player = player;
	    notify(player, "do_look_around()");
	}
    } else {
	welcome_user (d);
    }
}

void parse_connect (const char *msg, char *command, char *user, char *pass)
{
    char *p;

    while (*msg && isascii(*msg) && isspace (*msg))
	msg++;
    p = command;
    while (*msg && isascii(*msg) && !isspace (*msg))
	*p++ = *msg++;
    *p = '\0';
    while (*msg && isascii(*msg) && isspace (*msg))
	msg++;
    p = user;
    while (*msg && isascii(*msg) && !isspace (*msg))
	*p++ = *msg++;
    *p = '\0';
    while (*msg && isascii(*msg) && isspace (*msg))
	msg++;
    p = pass;
    while (*msg && isascii(*msg) && !isspace (*msg))
	*p++ = *msg++;
    *p = '\0';
}

void close_sockets()
{
    struct descriptor_data *d, *dnext;

    for (d = descriptor_list; d; d = dnext) {
	dnext = d->next;
	ssize_t bytes_written = write (d->descriptor, shutdown_message, strlen (shutdown_message));
        (void) bytes_written;
	if (shutdown (d->descriptor, 2) < 0)
	    perror ("shutdown");
	close (d->descriptor);
    }
    close (sock);
}

void emergency_shutdown()
{
	close_sockets();
}

void bailout(int sig)
{
    char message[1024];
    
    sprintf (message, "BAILOUT: caught signal %d", sig);
    panic(message);
    _exit (7);
    return;
}

void dump_status(int sig)
{
    struct descriptor_data *d;
    long now;

    (void) sig;
    (void) time (&now);
    fprintf (stderr, "STATUS REPORT:\n");
    for (d = descriptor_list; d; d = d->next) {
	if (d->connected) {
	    fprintf (stderr, "PLAYING descriptor %d player %s(%d)",
		     d->descriptor, db[d->player].name, d->player);

	    if (d->last_time)
		fprintf (stderr, " idle %d seconds\n",
			 (int)(now - d->last_time));
	    else
		fprintf (stderr, " never used\n");
	} else {
	    fprintf (stderr, "CONNECTING descriptor %d", d->descriptor);
	    if (d->last_time)
		fprintf (stderr, " idle %d seconds\n",
			 (int)(now - d->last_time));
	    else
		fprintf (stderr, " never used\n");
	}
    }
    return;
}

void dump_users(struct descriptor_data *e)
{
    struct descriptor_data *d;
    long now;
    char buf[1024];

    (void) time (&now);
    queue_string (e, "Current Players:\n");
    for (d = descriptor_list; d; d = d->next) {
	if (d->connected) {
	    if (d->last_time)
		sprintf (buf, "%s idle %d seconds\n",
			 db[d->player].name,
			 (int)(now - d->last_time));
	    else
		sprintf (buf, "%s idle forever\n",
			 db[d->player].name);
	    queue_string (e, buf);
	}
    }
}
