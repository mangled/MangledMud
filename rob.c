#include "copyright.h"

/* rob and kill */

#include "db.h"
#include "config.h"
#include "interface.h"
#include "match.h"
#include "externs.h"

void do_rob(dbref player, const char *what)
{
    dbref loc;
    dbref thing;
    char buf[BUFFER_LEN];

    if((loc = getloc(player)) == NOTHING) return;
    
    init_match(player, what, TYPE_PLAYER);
    match_neighbor();
    match_me();
    if(Wizard(player)) {
	match_absolute();
	match_player();
    }
    thing = match_result();

    switch(thing) {
      case NOTHING:
	notify(player, "Rob whom?");
	break;
      case AMBIGUOUS:
	notify(player, "I don't know who you mean!");
	break;
      default:
	if(Typeof(thing) != TYPE_PLAYER) {
	    notify(player, "Sorry, you can only rob other players.");
	} else if(db[thing].pennies < 1) {
	    sprintf(buf, "%s is penniless.", db[thing].name);
	    notify(player, buf);
	    sprintf(buf,
		    "%s tried to rob you, but you have no pennies to take.",
		    db[player].name);
	    notify(thing, buf);
	} else if(can_doit(player, thing,
			   "Your conscience tells you not to.")) {
	    /* steal a penny */
	    db[player].pennies++;
	    db[thing].pennies--;
	    notify(player, "You stole a penny.");
	    sprintf(buf, "%s stole one of your pennies!", db[player].name);
	    notify(thing, buf);
	}
	break;
    }
}

void do_kill(dbref player, const char *what, int cost)
{
    dbref victim;
    char buf[BUFFER_LEN];

    init_match(player, what, TYPE_PLAYER);
    match_neighbor();
    match_me();
    if(Wizard(player)) {
	match_player();
	match_absolute();
    }
    victim = match_result();

    switch(victim) {
      case NOTHING:
	notify(player, "I don't see that player here.");
	break;
      case AMBIGUOUS:
	notify(player, "I don't know who you mean!");
	break;
      default:
	if(Typeof(victim) != TYPE_PLAYER) {
	    notify(player, "Sorry, you can only kill other players.");
	} else if(Wizard(victim)) {
	    notify(player, "Sorry, Wizards are immortal.");
	} else {
	    /* go for it */
	    /* set cost */
	    if(cost < KILL_MIN_COST) cost = KILL_MIN_COST;

	    /* see if it works */
	    if(!payfor(player, cost)) {
		notify(player, "You don't have enough pennies.");
	    } else if((random() % KILL_BASE_COST) < cost) {
		/* you killed him */
		sprintf(buf, "You killed %s!", db[victim].name);
		notify(player, buf);

		/* notify victim */
		sprintf(buf, "%s killed you!", db[player].name);
		notify(victim, buf);
		sprintf(buf, "Your insurance policy pays %d pennies.",
			KILL_BONUS);
		notify(victim, buf);

		/* pay off the bonus */
		db[victim].pennies += KILL_BONUS;

		/* send him home */
		send_home(victim);

		/* now notify everybody else */
		sprintf(buf, "%s killed %s!",
			db[player].name, db[victim].name);
		notify_except(db[db[player].location].contents, player, buf);
	    } else {
		/* notify player and victim only */
		notify(player, "Your murder attempt failed.");
		sprintf(buf, "%s tried to kill you!", db[player].name);
		notify(victim, buf);
	    }
	break;
	}
    }
}

void do_give(dbref player, char *recipient, int amount)
{
    dbref who;
    char buf[BUFFER_LEN];

    /* do amount consistency check */
    if(amount < 0 && !Wizard(player)) {
	notify(player, "Try using the \"rob\" command.");
	return;
    } else if(amount == 0) {
	notify(player, "You must specify a positive number of pennies.");
	return;
    }

    /* check recipient */
    init_match(player, recipient, TYPE_PLAYER);
    match_neighbor();
    match_me();
    if(Wizard(player)) {
	match_player();
	match_absolute();
    }
    
    switch(who = match_result()) {
      case NOTHING:
	notify(player, "Give to whom?");
	return;
      case AMBIGUOUS:
	notify(player, "I don't know who you mean!");
	return;
      default:
	if(!Wizard(player)) {
	    if(Typeof(who) != TYPE_PLAYER) {
		notify(player, "You can only give to other players.");
		return;
	    } else if(db[who].pennies + amount > MAX_PENNIES) {
		notify(player, "That player doesn't need that many pennies!");
		return;
	    }
	}
	break;
    }

    /* try to do the give */
    if(!payfor(player, amount)) {
	notify(player, "You don't have that many pennies to give!");
    } else {
	/* he can do it */
	sprintf(buf, "You give %d %s to %s.",
		amount,
		amount == 1 ? "penny" : "pennies",
		db[who].name);
	notify(player, buf);
	if(Typeof(who) == TYPE_PLAYER) {
	    sprintf(buf, "%s gives you %d %s.",
		    db[player].name,
		    amount,
		    amount == 1 ? "penny" : "pennies");
	    notify(who, buf);
	}

	db[who].pennies += amount;
    }
}
