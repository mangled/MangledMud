<img src="./mud.png" alt="MangledMud"/>

MangledMud
==========

MangledMud is a pure ruby port of [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD).

The port has been a painstaking exercise in testing! All of the original "C" code was wrapped in ruby extensions,
unit tests added, line coverage checked then ruby replacements implemented which matched the original's behaviour.
The full history of this port is held in the git repository, should you wish to delve.

In its present form it is structured almost as per the original and the code is still "C" rather than ruby orientated.

Please enjoy, this is a great MUD and its history deserves to be retained and the code lived in.

- [MangledMe](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)
- [Alex]()

Trying it out
-------------

We are running a server at TODO, you can try the MUD out by, say telnet'ing in to it: `telnet xyz 4201`. For documentation
see the associated [Three's Unabridged Dictionary of Commands](./file.guide.html).

Install
-------

The code has been tested on Linux, Mac and Windows. For Linux and Mac we used `ruby 1.9.2p290` and `ruby 1.9.3-p125`
on windows with the associated dev. kit installed.

Pull the code, in the main directory:

    $ gem install bundler
    $ bundle install

Testing
-------

The code is very well tested. The deafult rake task is to run the unit tests:

    $ rake

Ignore the various stdout/stderr messages, these are "original" informal output.

There is a networking test also, this tests sockets etc. to run this you need to
start the mud server and execute the interface tests, e.g.:

    $ ruby ./lib/mud.rb minimal.db dump

In another terminal (for example):

    $ ruby ./test/interface_test.rb

Running
-------

To run the server, type:

    $ ruby ./lib/mud.rb minimal.db dump

You can also specify the port on which to run. TODO - We should set the host too? Two database's are provided:

* `minimal.db` : A tiny database, containing, well the minimal amount!
* `small.db` : A slightly larger database

To connect, launch `telnet (localhost 4201)`, for example, or use a more advanced client such as [TinTin++](http://tintin.sourceforge.net/index.php)

The Wizard player is always defined, you connect as them by typing:

    > connect wizard potrzebie

We have converted the original [Three's Unabridged Dictionary of Commands](./file.guide.html), if you `rake doc:yard` you will get local documentation (under doc).

Version
-------

We chose to port [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD) version 1.4.1. This is a fairly early edition, it lacks some of the later incarnations
features, mainly TODO... This specific version was chosen as it had the least code pollution, later versions were filled with #define's. We believe
that it would be a simple step to port specific commands now that the code is in place - Through diff'ing the changes to the original and applying
the desired functionality.

License
-------

Before putting the code on GitHub we followed the original license and received a blessing from [James Aspnes](https://en.wikipedia.org/wiki/James_Aspnes).
We would ask that any further development also follows the intent of the original license. The important aspect being to credit the original author(s)
and make sure it is obvious that the source is derived from [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD).

Enhancements
------------

There are a number of possible enhancements, the one major area for improvement is refactoring the database from in-memory to some kind of true database.

We also shifted the majority of the code to use a "phrasebook", localization would also now be trivially possible.

Because of the database structure the networking code is non-threaded, it handles each request in turn. It would be nice to see the networking improved,
neither of us are experts in this area and we are pretty sure its not as robust as it could be :-)

It would be nice to see the code extended to support the full command set.

If you wish to extend this then please maintain the high level of unit test coverage. We only request that the master branch progress along the lines
of the original, even if it's innards are replaced entirely it should still run like the original and support importing original database files.

Fancy helping port a MUD?
-------------------------

We have been bitten by this exercise and are considering porting the LambdaMoo or a later variant of TinyMud, e.g. MUCK
- If you would like to help then please contact [me](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)
