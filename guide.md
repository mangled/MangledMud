Three's Dictionary and Encyclopedia
===================================

Introduction
------------

This is an almost carbon copy of the original documentation associated with [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD).
We have reproduced it here as its a good guide to the commands and also follows our goal of
trying to record and preserve the history of this MUD for the 1.0 release of MangledMUD.

MangledMUD 1.0 is based on a relatively early version of [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD) so some commands introduced later in its life,
[WHISPER](#WHISPER) for example, are unimplemented and are marked as such. Please see the main readme for comments on the version
we chose to port and why.

* [MangledMe](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)

Three's Unabridged Dictionary of Commands
-----------------------------------------

> "These docs were written with the help of Three, who wrote probably the
> best library I've seen. Contained herein are her docs, and some examples
> that I've written. - Chrys"

#### <a id="DROP"/>DROP

    drop [object]

Drops `[object]`. Dropping a thing in the [TEMPLE](#TEMPLE) sacrifices [SACRIFICING](#SACRIFICING) it. Otherwise, a dropped thing is relocated to the current room, unless its [STICKY](#STICKY) flag is set, or the room has a [DROP-TO](#DROP-TO). Unlinked exits can only be dropped in rooms you [CONTROL](#CONTROL). `throw` is the same as `drop`.

#### <a id="EXAMINE"/>EXAMINE
    examine [object]

Displays all available information about `[object]`. Object can be specified as name or `#number`, or as `me` or `here`. You must [CONTROL](#CONTROL) the object to [EXAMINE](#EXAMINE) it. Wizards can [EXAMINE](#EXAMINE) objects in other rooms using `#number` or `*player`.

#### <a id="GET"/>GET
    get [object]

Picks up `[object]`. `[object]` can be a thing or an unlinked exit. `take` is the same as `get`.

#### <a id="GIVE"/>GIVE
    give [player]=[pennies]

Gives `[player]` the specified number of `[pennies]`. The only thing you can [GIVE](#GIVE) is pennies. You can't [GIVE](#GIVE) someone pennies if their new total would be greater than 10000. Wizards can [GIVE](#GIVE) as many pennies as they wish, even negative amounts, without affecting their own supply, and can [GIVE](#GIVE) pennies to things to change their sacrifice values.

#### <a id="GOTO"/>GOTO
    goto [direction]
    goto [home]

Goes in the specified direction. `go home` is a special command that returns you to your starting location. The word `go` may be omitted. `move` is the same as `go`.

#### <a id="GRIPE"/>GRIPE
    gripe [message]

Sends `[message]` to the system maintainer.

#### <a id="HELP"/>HELP
    help

This displays a short help message.

#### <a id="INVENTORY"/>INVENTORY
    inventory

Lists what you are carrying. This can usually be abbreviated to inv.

#### <a id="KILL"/>KILL
    kill [player][=cost]

Attempts to kill the specified player. Killing [COSTS](#COSTS) either `[cost]` or 10 pennies, whichever is greater. The probability of [SUCCESS](#SUCCESS) is `[cost]` percent. Spending 100 pennies always works (except against wizards, [WHO](#WHO) can never be killed). *Unimplemented - Players cannot be killed in rooms which have been set [HAVEN](#HAVEN)*.

#### <a id="LOOK"/>LOOK
    look [object]

Displays the description of `[object]`, or the room you're in if you don't specify one. `[object]` can be a thing, player, exit, or room, specified as `name` or `#number` or `me` or `here`. `read` is the same as 'look'. Wizards can [LOOK](#LOOK) at objects in other rooms using `#number` or `*player`

#### <a id="MOVE"/>MOVE

  See [GOTO](#GOTO)

#### <a id="NEWS"/>NEWS
    news

Displays the current news file for the game. Must be typed in full.

#### <a id="PAGE"/>PAGE
    page [player]

This tells a player that you are looking for them. They will get a message telling them your name and location. This [COSTS](#COSTS) 1 penny. If a player is set [HAVEN](#HAVEN), you cannot [PAGE](#PAGE) them, and they will not be notified that you tried (*note: haven is unimplemented*).

#### <a id="QUIT"/>QUIT
    QUIT

Log out and leave the game. Must be in capitals.

#### <a id="READ"/>READ

See [LOOK](#LOOK).

#### <a id="ROB"/>ROB
    rob [player]

Attempts to steal one penny from `[player]` The only thing you can rob are pennies.

#### <a id="SAY"/>SAY
    say [message]

Says `[message]` out loud. You can also use `"[message]`. Another command is `:[message]`. This is used for actions, ex. if your name was Igor, and you typed `:falls down.`, everyone would see `"Igor falls down."` See also [WHISPER](#WHISPER) (*note: whisper is unimplemented*).

#### <a id="SCORE"/>SCORE
    score

Displays how many pennies you are carrying.

#### <a id="TAKE"/>TAKE

See [GET](#GET).

#### <a id="THROW"/>THROW

See [DROP](#DROP).

#### <a id="WHISPER"/>WHISPER (*Unimplemented*)
    whisper [player]=[message]

Whispers the message to the named person, if they are in the same room as you. No one else can see the message. Wizards can [WHISPER](#WHISPER) `*[player]=[message]` to whisper to players in other rooms.

#### <a id="WHO"/>WHO
    WHO [player]

List the name of every player currently logged in, and how long they have been inactive. If given a player name, it displays only that name and idle time. Must be in all capitals. There are two player [FLAGS](#FLAGS) that pertain to the formatting of [WHO](#WHO), [REVERSE_WHO](#REVERSE_WHO) and [TABULAR_WHO](#TABULAR_WHO) (*note: neither of these flags are implemented*). See also [FLAGS](#FLAGS).

#### <a id="@BOOT"/>@BOOT (*Unimplemented*)
    @boot [player]

Disconnects the player from the game. Only Wizards can use this command.

#### <a id="@CHOWN"/>@CHOWN
    @chown [object]=[player]

Changes the ownership of `[object]` to `[player]` Only wizards may use this command. Players can't be @chowned; they always own themselves.

#### <a id="@CREATE"/>@CREATE
    @create [name][=cost]

Creates a thing with the specified `[name]`. Creation [COSTS](#COSTS) either `[cost]` pennies or 10 pennies, whichever is greater. The value of a thing is proportional to its cost. To be exact, value=(cost/5)-1.

#### <a id="@DESCRIBE"/>@DESCRIBE
    @describe [object][=description]

`[object]` can be a thing, player, exit, or room, specified as `name` or `#number` or `me` or `here`. This sets the description a player sees when they use the command `look [object]`. Without a description argument, it clears the message. It can be abbreviated `@desc`.

#### <a id="@DIG"/>@DIG
    @dig [name]

Creates a new room with the specified name and displays its number. This [COSTS](#COSTS) 10 pennies.

#### <a id="@DUMP"/>@DUMP
    @dump

Only wizards may use this command. Saves the database from memory to disk. Automatically occurs every hour, and when [@SHUTDOWN](#@SHUTDOWN) is used.

#### <a id="@FAIL"/>@FAIL
    @fail [object][=message]

`[object]` can be a thing, player, exit, or room, specified as `name` or `#number` or `me` or `here`. Sets the fail message for `[object]`. The message is displayed when a player fails to use `[object]` Without a message argument, it clears the message. See also [@OFAIL](#@OFAIL).

#### <a id="@FIND"/>@FIND
    @find [name]

Displays the name and number of every room, thing, or player that you [CONTROL](#CONTROL) whose name matches `[name]` Because the command is computationally expensive, this [COSTS](#COSTS) 1 penny.

#### <a id="@FORCE"/>@FORCE
    @force [player]=[command]

Only wizards may use this command. Forces the game to act as though `[player]` had entered `[command]`

#### <a id="@LINK"/>@LINK
    @link [object]=[number]
    @link [object]=here
    @link [dir][room]=home

Links `[object]` to room specified by `[number]`. For things and players, sets the [HOMES](#HOMES) room. For rooms, sets the [DROP-TO](#DROP-TO) room. For exits, sets the target room; exits must be unlinked, and you must [CONTROL](#CONTROL) the target room unless its [LINK_OK](#LINK_OK) flag is set. [LINKING](#LINKING) an exit [COSTS](#COSTS) 1 penny. If the exit was owned by someone else, the former owner is reimbursed 1 penny. Wizards can link objects in other rooms using `#number` or `*player`.

#### <a id="@LOCK"/>@LOCK
    @lock [object]=[key]

Locks `[object]` to a specific key(s). `[object]` can be specified as `name` or `#number`, or as `me` or `here`. Boolean expressions are allowed, using `&` (and), \` (or), `!` (not), and parentheses `()` for grouping (*note the boolean expression `!` (not) is implemented, the rest are unimplemented*). To lock to a player, prefix their name with `*` (ex. `*Igor`). See the examples section examples.

#### <a id="@NAME"/>@NAME
    @name [object]=<new name> [password]

Changes the name of `[object]`. `[object]` can be a thing, player, exit, or room, specified as `name` or `#number` or `me` or `here`. For a player, it requires the player's password.

#### <a id="@NEWPASSWORD"/>@NEWPASSWORD (*Unimplemented*)
    @newpassword [player][=password]

Only wizards may use this command. Changes `[player]`'s password, informing `[player]` that you changed it. Must be typed in full.

#### <a id="@OFAIL"/>@OFAIL
    @ofail [object][=message]

The ofail message, prefixed by the player's name, is shown to others when the player fails to use `[object]`. Without a message argument, it clears the message. `[object]` can be specified as `name` or `#number`, or as `me` or `here`. See also [@FAIL](#@FAIL).

#### <a id="@OPEN"/>@OPEN
    @open [dir][;<other dir>]* [=number]

Creates an exit in the specified direction(s). If `[number]` is specified, it is linked to that room. Otherwise, it is created unlinked. You or anyone else may use the [@LINK](#@LINK) command to specify where the unlinked exit leads. Opening an exit [COSTS](#COSTS) 1 penny. If you specify `[number]`, [LINKING](#LINKING) [COSTS](#COSTS) 1 more penny.

#### <a id="@OSUCCESS"/>@OSUCCESS
    @osuccess [object][=message]

The osuccess message, prefixed by the player's name, is shown to others when the player successfully uses `[object]`. Without a message argument, it clears the message. It can be abbreviated @osucc. `[object]` can be specified as `name` or `#number`, or as `me` or `here`. See also [@SUCCESS](#@SUCCESS).

#### <a id="@PASSWORD"/>@PASSWORD
    @password <old password>=<new password>

This changes your password.

#### <a id="@SET"/>@SET
    @set [object]=[flag]
    @set [object]=![flag]

Sets (or, with '!', unsets) `[flag]` on `[object]`. See [FLAGS](#FLAGS) in the encyclopedia.

#### <a id="@SHUTDOWN"/>@SHUTDOWN
    @shutdown

Only wizards may use this command. Shuts down the game. Must be typed in full.

#### <a id="@STATS"/>@STATS
    @stats [player]

Display the number of objects in the game. For wizards, also lists a breakdown by object types. Wizards can supply a player name to count only objects owned by that player.

#### <a id="@SUCCESS"/>@SUCCESS
    @success [object] [=[message]]

Sets the success message for `[object]`. The message is displayed when a player successfully uses `[object]`. Without a message argument, it clears the message. It can be abbreviated @succ. `[object]` can be specified as `name` or `#number`, or as `me` or `here`. See also [@OSUCCESS](#@OSUCCESS).

#### <a id="@TELEPORT"/>@TELEPORT
    @teleport [object=] [room]

Teleports `[object]` to `[room]` `[object]` must be a thing. (Wizards can also teleport players.) You must be able to link to the destination, and either [CONTROL](#CONTROL) the object or its current location. You can only teleport objects into a room, not into someone's [INVENTORY](#INVENTORY). If the target room has a [DROP-TO](#DROP-TO), `[object]` will go to the [DROP-TO](#DROP-TO) room instead. Wizards can teleport things into players' inventories.

#### <a id="@TOAD"/>@TOAD
    @toad [player]

Only wizards may use this command. Turns the player into a slimy toad, [DESTROYING](#DESTROYING) their character. Must be typed in full.

#### <a id="@UNLINK"/>@UNLINK
    @unlink [dir]
    @unlink here

Removes the link on the exit in the specified direction, or removes the [DROP-TO](#DROP-TO) on the room. Unlinked exits may be picked up and dropped elsewhere. Be careful, anyone can relink an unlinked exit, becoming its new owner (but you will be reimbursed your 1 penny). See [@LINK](#@LINK).

#### <a id="@UNLOCK"/>@UNLOCK
    @unlock [object]

Removes the lock on `[object]`. See [@LOCK](#@LOCK).

#### <a id="@WALL"/>@WALL
    @wall [message]

Only wizards may use this command. Shouts something to every player connected. Must be typed in full.

Three's Encyclopedia of the TinyWorld
-------------------------------------

#### BEING KILLED

Getting killed is no big deal. If you are killed, you return to your home, and all things you carry return to their [HOMES](#HOMES). You also collect 50 pennies in insurance [MONEY](#MONEY) (unless you have >= 10000 pennies). See [MONEY](#MONEY).

#### BOGUS COMMANDS

Bogus commands can be made using exits. For example, to make a `sit` command, one could `@open sit`, then `@link sit=here` (because unlinked exits can be stolen), `@lock sit=me&!me` (impossible to be both at once, therefore always fails), and `@fail sit=You sit on the chair.`; `@ofail=sits on the chair.`. Since nobody can go through it, it always fails. The [@FAIL](#@FAIL) message is displayed to the player, and the [@OFAIL](#@OFAIL) message (preceded by the player's name) to everyone else. Note this version does not support the '!' operator, so you have to lock to yourself or a fake player to achieve similar results. See [@LOCK](#@LOCK).

#### <a id="CONTROL"/>CONTROL

There are 3 rules to controlling objects:

1. You [CONTROL](#CONTROL) anything you own.
2. A [WIZARD](#WIZARD) controls everything.
3. Anybody controls an [@UNLINK](#@UNLINK)'d exit, even if it is [@LOCK](#@LOCK)ed. 

Builders (*note builders are unimplemented*) should beware of 3, lest their exits be linked or stolen.

#### <a id="COSTS"/>COSTS

* [KILL](#KILL): 10p (or more, up to 100p).
* [PAGE](#PAGE): 1p.
* [@DIG](#@DIG): 10p.
* [@CREATE](#@CREATE): 10p (or more, up to 505p), sacrifice
  value=(cost/5)-1.
* [@FIND](#@FIND): 1p.
* [@LINK](#@LINK): 1p (if you didn't already own it, +1p to the
  previous owner).
* [@OPEN](#@OPEN): 1p (2p if linked at the same time). 

Wizards do not need [MONEY](#MONEY) to do anything.

#### <a id="DESTROYING"/>DESTROYING

Nothing can be destroyed. However, everything can be reused. You can [GIVE](#GIVE) an object a new name with [@NAME](#@NAME), redescribe it with [@DESCRIBE](#@DESCRIBE), and set new [SUCCESS](#SUCCESS) and fail messages for it. Exits can be [@UNLINK](#@UNLINK)'d and picked up and dropped elsewhere, so you can pick up an extra exit and use it in another room.

#### <a id="DROP-TO"/>DROP-TOs

When the [@LINK](#@LINK) command is used on a room, it sets a [DROP-TO](#DROP-TO) location. Any object dropped in the room (if it isn't [STICKY](#STICKY)) will go to that location. If the room is [STICKY](#STICKY), the [DROP-TO](#DROP-TO) will be delayed until the last person in the room has left.

#### <a id="FAILURE"/>FAILURE

You fail to use a thing when you cannot [TAKE](#TAKE) it (because it's lock fails). You fail to use an exit when you cannot go through it (because it's unlinked or locked). You fail to use a person when you fail to [ROB](#ROB) them. You fail to use a room when you fail to [LOOK](#LOOK) around (because it's locked). See [STRINGS](#STRINGS), and in the dictionary, [@FAIL](#@FAIL) and [@OFAIL](#@OFAIL).

#### <a id="FLAGS"/>FLAGS

[FLAGS](#FLAGS) are displayed as letters following an object's ID number. [FLAGS](#FLAGS) are set with the [@SET](#@SET) command. The flags are:

  * `A(bode)` [ABODE](#ABODE) (*not implemented*)
  * `B(uilder)` (*not implemented*)
  * `C(hown_OK) CHOWN_OK` (*not implemented*)
  * `D(ark)` [DARK](#DARK)
  * `H(aven)` [HAVEN](#HAVEN) (*not implemented*)
  * `J(ump_OK) JUMP_OK` (*not implemented*)
  * `L(ink_OK)` [LINK_OK](#LINK_OK)
  * `S(ticky)` [STICKY](#STICKY)
  * `T(emple)` [TEMPLE](#TEMPLE)
  * `W(izard)` [WIZARD](#WIZARD)
  * and the [GENDER](#GENDER) flags (*not implemented*)
    * `M(ale)`
    * `F(emale)`
    * `N(euter)`

The [WHO](#WHO) list also uses [REVERSE_WHO](#REVERSE_WHO) and [TABULAR_WHO](#TABULAR_WHO) (*both unimplemented*), but they do not show up in the ID number. Some systems also use B(uilder) (*not implemented*). See TYPES, [GENDER](#GENDER) (*not implemented*), and individual flag names.

##### <a id="WIZARD"/>WIZARD

If a person is wizard, they are a wizard, unkillable, subject to fewer restrictions, and able to use wizard commands. It is only meaningful for players. Only another wizard can set this flag. In general, WIZARDs can do anything using `#number` or `*player` Only player `#1` can set and unset the wizard flag of other players. No wizard can turn their own wizard flag off. See [FLAGS](#FLAGS) and [@SET](#@SET).

##### <a id="STICKY"/>STICKY

If a thing is sticky, it goes [HOME](#HOMES) when dropped. If a room is sticky, its [DROP-TO](#DROP-TO) is delayed until the last person leaves Only meaningful for things and rooms.

##### <a id="LINK_OK"/>LINK_OK

If a room is `LINK_OK`, anyone can link exits to it (but still not from it). It has no meaning for people, things, or exits. See [@LINK](#@LINK) in the dictionary.

##### <a id="DARK"/>DARK

If a room is dark, then when people besides the owner `look` there, they only see things they own. If a thing or player is dark, then `look` does not list that object in the room's contents. Only wizards can set players or things dark.

##### <a id="TEMPLE"/>TEMPLE

If a room is a temple, you can sacrifice things for pennies by dropping them there. It has no meaning for players, things, or exits. Only wizards can set this flag.

##### <a id="GENDER"/>GENDER (*Unimplemented*)

    @set [ME](#ME)=unassigned`male`female`neuter (Default unassigned)

If a player's gender is set, `%`-substitutions will use the appropriate pronoun for that player. Only meaningful for players. See [SUBSTITUTIONS](#SUBSTITUTIONS).

##### <a id="HAVEN"/>HAVEN (*Unimplemented*)
    @set [HERE](#HERE)=haven
    @set [ME](#ME)=haven

If a room is haven, you cannot [KILL](#KILL) in that room. If a player is set haven, he cannot be paged.

##### <a id="ABODE"/>ABODE (*Unimplemented*)
    @set [HERE](#HERE)=abode

If a room is set abode, players can set their [HOMES](#HOMES) there, and can set the [HOMES](#HOMES) of objects there. ([LINK_OK](#LINK_OK) is now used only for exits, and abode is for players and objects.)

##### <a id="REVERSE_WHO"/>REVERSE_WHO (*Unimplemented*)
    @set [ME](#ME)=reverse_who

If this flag is set, the [WHO](#WHO) list will be displayed in reverse order, with newest players listed last. This flag can only be set on players.

##### <a id="TABULAR_WHO"/>TABULAR_WHO (*Unimplemented*)
    @set [ME](#ME)=tabular_who

If this flag is set, the [WHO](#WHO) list will be displayed in a tabular form. This flag can only be set on players.

#### <a id="GOAL"/>GOAL

There is no ultimate goal to this game, except to have fun. There are puzzles to solve, scenery to visit, and people to meet. There are no winners or losers, only fellow players. Enjoy.

#### <a id="HERE"/>HERE

The word `here` refers to the room you are in. For example, to rename the room you're in (if you [CONTROL](#CONTROL) it), you could enter `@name [HERE](#HERE)=<new name>`.

#### <a id="HOMES"/>HOMES

Every thing or player has a home. This is where things go when sacrificed, players when they go home, or things with the [STICKY](#STICKY) flag set go when dropped. Homes are set with the [@LINK](#@LINK) command. A thing's home defaults to the room where it was created, if you [CONTROL](#CONTROL) that room, or your home. You can link an exit to send players home (with their [INVENTORY](#INVENTORY)) by `@link <dir>=home`. [DROP-TO](#DROP-TO)s can also be set to `home`. See [@LINK](#@LINK).

#### <a id="LINKING"/>LINKING

You can link to a room if you [CONTROL](#CONTROL) it, or if it is set [LINK_OK](#LINK_OK) or [ABODE](#ABODE) (*abode is not implemented*). Being able to link means you can set the [HOMES](#HOMES) of objects or yourself to that room if it is set [ABODE](#ABODE), and can set the destination of exits to that room if it is [LINK_OK](#LINK_OK). See [@LINK](#@LINK).

#### <a id="ME"/>ME

The word `me` refers to yourself. Some things to do when starting out:

1. Give yourself a description with `@describe [ME](#ME)=[description]`, then [LOOK](#LOOK) at yourself with `look [ME](#ME)`.
2. Prevent anyone else from robbing you with `@lock [ME](#ME)=me`.
3. Set your [GENDER](#GENDER) (*not implemented*), if you wish it known, with `@set [ME](#ME)=male` or `@set [ME](#ME)=female` (or `@set [ME](#ME)=neuter` to be an `it`).

#### <a id="MONEY"/>MONEY

Building and some other actions cost [MONEY](#MONEY). How to get money:

1. Find pennies.
2. Sacrifice (drop) things in the [TEMPLE](#TEMPLE).
3. Get killed.
4. Be given money.
5. [ROB](#ROB) someone.

Once you reach 10000 pennies, it becomes difficult to acquire more. See [COSTS](#COSTS) and [SACRIFICING](#SACRIFICING). Wizards don't need money to do anything.

#### <a id="ROBBERY"/>ROBBERY

When you [ROB](#ROB) someone, you succeed or fail to use them (See [SUCCESS](#SUCCESS) and [FAILURE](#FAILURE)). You can protect yourself from being robbed by entering `@lock [ME](#ME)=me` (See [ME](#ME), and in the dictionary, [@LOCK](#@LOCK)). If you lock yourself to yourself, you can [ROB](#ROB) yourself and set off your [@SUCCESS](#@SUCCESS) and [@OSUCCESS](#@OSUCCESS) messages. Try entering `@osucc [ME](#ME)=is goofy.` and robbing yourself in a crowd.

See [ROB](#ROB) in the dictionary.

#### <a id="SACRIFICING"/>SACRIFICING

You sacrifice a thing by dropping it in the [TEMPLE](#TEMPLE). Sacrificing an object gives you the value of an object. You can't sacrifice something you own. If you have >= 10000 pennies, all sacrifices are worth only 1 penny. The sacrifice value of a thing is set at creation by `@create frob=cost`, by the formula value=(cost/5)-1. Only a [WIZARD](#WIZARD) can change the value of an object, once created.

#### <a id="STRINGS"/>STRINGS

Objects have 6 strings:

1. A name.
2. A description.
3. A [SUCCESS](#SUCCESS) message (seen by the player).
4. A fail message (seen by the player).
5. An osuccess message (seen by others).
6. An ofail message (seen by others).

#### <a id="SUBSTITUTIONS"/>SUBSTITUTIONS (*Unimplemented*)

[@OSUCCESS](#@OSUCCESS) and [@OFAIL](#@OFAIL) messages may contain `%`-substitutions, which evaluate to [GENDER](#GENDER)-specific pronouns if the player's [GENDER](#GENDER) is set. They are:

* `%s` (subjective) = Name, he, she, it.
* `%o` (objective) = Name, him, her, it.
* `%p` (possessive) = Name's, his, her, its.
* `%n` (player's name) = Name. 

Capitalized pronouns are also available with `%S`, `%O`, and `%P`. If you need a `%`, use `%%`. Example: `@ofail teapot=burns %p hand on the hot teapot.` See [GENDER](#GENDER)

#### <a id="SUCCESS"/>SUCCESS

You successfully use an object when you [TAKE](#TAKE) it. You use an exit successfully when you go through it. You successfully use a person successfully when you successfully [ROB](#ROB) them. You successfully use a room when you [LOOK](#LOOK) around. See [STRINGS](#STRINGS), and in the dictionary, [@SUCCESS](#@SUCCESS) and [@OSUCCESS](#@OSUCCESS).

#### TYPES OF OBJECTS

There are 4 types of objects:

1. `Things` are inanimate objects that can be carried.
2. `Players` are animate objects that can move and carry.
3. `Exits` are the means by which objects move.
4. `Rooms` are locations that contain objects and linked exits. 

The first letter following an object's ID number indicates the type:

* `P`(layer)
* `E`(xit)
* `R`(oom)
* (otherwise) `T`(hing)

Examples
--------

Igor is a new player. He sets his description by typing:

    @desc me=Igor is a ferret with an evil glint in his eye.

He has guarded himself from being robbed, and set some fail messages on himself that people will see when they try to [ROB](#ROB) him. He typed:

    @lock me=me
    @fail me=Igor chomps you on the knee with his little sharp teeth.
    @ofail me=howls in pain as Igor bites them.

Now, here is what happens if Murf tries to [ROB](#ROB) Igor:

    Murf types:   rob igor
    Murf sees:    Igor chomps you on the knee with his little sharp teeth.
    all else see: Murf howls in pain as Igor bites them.

`them` as a pronoun isn't to specific, and so Igor should do this (*note string substitutions are unimplemented*):

    @ofail me=howls in pain as Igor bites %o.

So if Murf robs Igor, this is what everyone else will see:

    Murf howls in pain as Igor bites him.

This is assuming that Murf did a `@set [ME](#ME)=male` (*note that gender is unimplemented*). If not, it would have printed:

    Murf howls in pain as Igor bites Murf.

Igor wants to set a message that he will use a lot, so he sets his @osucc:

    @osucc me=runs around the room nipping at everyone's heels.

Now, if he wants to display that message:

    Igor types:   rob me
    Igor sees:    You stole a penny.
    Igor stole one of your pennies!
    all else see: Igor runs around the room nipping at everyone's heels.

Igor wants to make an object called 'Ferret chow'. He types:

    @create Ferret Chow
    @desc Ferret Chow=This is a big bag full of yummy ferret chow.
    @succ Ferret Chow=You tear into the end of the bag, stuffing yourself.
    @osucc Ferret Chow=tears into the Ferret Chow bag, eating greedily.

Now Igor decides that he wants to be the only one [WHO](#WHO) can pick up the bag.

    @lock Ferret Chow=me
    @fail Ferret Chow=It's icky Ferret Chow. It would probably taste gross.
    @ofail Ferret Chow=decides Ferret Chow is icky.

If Igor picks up the bag:

    Igor types:   get Ferret Chow
    Igor sees:    You tear into the end of the bag, stuffing yourself.
    all else see: Igor tears into the Ferret Chow bag, eating greedily.

Igor is now carrying the bag. He must [DROP](#DROP) it if he wants to see the messages again. If Murf picks up the bag:

    Murf types:   get Ferret Chow
    Murf sees:    It's icky Ferret Chow. It would probably taste gross.
    all else see: Murf decides Ferret Chow is icky.

Because the bag was locked to Igor, Murf cannot [GET](#GET) the bag.

Igor wants to build a few rooms. He can only build off of a place where he can get a link. He needs to ask around to find one of these if he is just starting to build. Murf is going to give Igor a link named `n;north`. That means that both `n` and `north` activate that exit. Igor digs a room, and links the exit to it. He types:

    @dig Igor's House

At this point, the program will respond "Igor's House created with room number xxxx". We'll pretend it gave the room number as 1234.

    @link n;north=1234

The program will respond with "Linked". Now Igor sets a few messages on the exit. He types:

    @desc n=North is Igor's House.
    @succ n=You crawl into Igor's House.
    @osucc n=crawls into Igor's House.

These messages work just the same way they work on object, like the Ferret Chow. Next, Igor goes in the room, and creates an out exit. Murf has been nice enough to not only give Igor the `n;north` exit, but to set his room to `L`(ink_ok). Murf's room number is `623`. Igor types `n` or `north` to go in the room, then types:

    @open out;back;s;south=623

The program will respond with `Opened. Trying to link... Linked`. Igor now has a south exit back to Murf's room. Murf can now set his room to !link_ok, so no one else can link to it. Igor puts some messages on the south link as well. He decides he wants to describe the room, so he types:

    @desc here=This is Igor's home. It is a small room, lined with paper shreds. Over in the corner is a small hole.

Now Igor wants to dig a small room that the hole connects to. He types:

    @dig Igor's Hidden Room

The program tells him that the room is number 1250. He then types:

    @open hole=1250
    @lock hole=me
    @desc hole=This is a small hole, just the size of Igor.
    @fail hole=You can't fit.
    @ofail hole=can't fit through the hole.
    @succ hole=You slip into the hole.
    @osucc hole=slips into the hole.

This creates and links the exit called `hole` to Igor's Hidden Room. He locks the exit to him, so only he can go through the exit. When he uses the exit, the [SUCCESS](#SUCCESS) and [@OSUCCESS](#@OSUCCESS) messages will be displayed. When someone else tries to use the exit, the [@FAIL](#@FAIL) and [@OFAIL](#@OFAIL) messages will be displayed. Since Igor owned the room that he was [LINKING](#LINKING) from, he had to use [@OPEN](#@OPEN) to create the link first. He now types `hole` to go in the room, and types `@open out=1234` to create and link an exit called `out` that leads to his House. If Igor wants everyone BUT Murf to be able to go `hole`, he types:

    @lock hole=!*murf

This locks the hole against the player Murf. If he wants a person to be able to go through `hole` only if they have the bag of Ferret Chow, he types:

    @lock hole=Ferret Chow

If he wants himself to be able to go in the hole, even if he doesn't have the Ferret Chow, he types:

    @lock hole=Ferret Chow me

If he wants to lock everyone out except for himself and Murf if Murf has the bag of Ferret Chow, he types (*note the `&` operator is unimplemented, so this is not possible in this version*):

    @lock hole=(*murf & Ferret Chow) me

You can get more and more complicated with locks this way. Igor is done building his home, and wants to set his home to it, so when he types `home` he will go there instead of `Limbo(#0)`. He goes in his house, and types:

    @link me=here

The program will respond with `Home set". Now Igor can go 'home'`, and [QUIT](#QUIT) and not worry about his inactive body cluttering up the landscape.

Creating whole houses and adventures can be easy if you understand the way the `@` commands work. When you build a room, you should have a very
thorough description. Every thing listed in the description should be given a bogus exit (see entry) to detail the place. For example, here is the description of a room built by Three.

    Threes flat(#5400)
    Red wall-to-wall carpeting covers the floor. A cushy brown leather
    couch sits across from a wide-screen TV with a VCR and video disc
    player stacked on top.  Escher prints hang on the walls, hilited by
    track lighting. Papers protrude from a roll-top desk to one side,
    adjoining an imposing stereo whose controls rival those of 747 cockpits.
    The kitchen lies north, the foyer south, and the bedroom beyond a
    short passage east.
    Contents:
    Flitterby Award for Comprehensive Building

Now, you noticed the desk in the room. A `look desk` will show:

    Every drawer and cubby is overflowing with papers, envelopes, flyers,
    leaflets, folders, booklets, binders, quick reference cards, and
    other paper products. A Compaq luggable sits in a small canyon of
    paper. Atop the desk stands a framed photo. Under the desk sits a
    back stool.

Now, since this was done with a exit to create a bogus command, you might try going through the exit, so you will get the fail message. A `desk` will show:

You rummage thru the desk drawers, finding nothing of interest.

Here is an [EXAMINE](#EXAMINE) of the bogus command, to show you how it was done:

    desk(#5395E)
    Owner: Three  Key: Three(#5370PTF)&!Three(#5370PTF) Pennies: 0
    Every drawer and cubby is overflowing with papers, envelopes, flyers,
    leaflets, folders, booklets, binders, quick reference cards, and
    other paper products. A Compaq luggable sits in a small canyon of
    paper. Atop the desk stands a framed photo. Under the desk sits a
    back stool.
    Fail: You rummage thru the desk drawers, finding nothing of interest.
    Ofail: rummages thru the desk drawers.
    Destination: Three's flat(#5400R)

In this way, a highly detailed room can be built, and greatly increase the atmosphere of the place. Take a walk around and look at the place first, before deciding to build. Then sit down and think carefully about what you want to build. Careful planning has made several very interesting places.
