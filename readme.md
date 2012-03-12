<img src="./mud.png" alt="MangledMud"/>

MangledMud
==========

MangledMud is a ruby port of [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD).

The port has been a labour of love and a painstaking exercise in testing! All of the original "C" code was wrapped in ruby extensions,
unit tests added, line coverage checked then ruby replacements implemented which matched the original's behaviour.
The full history of this port is held in the git repository, should you wish to delve.

In its present form it is structured almost as per the original and the code is still "C" rather than ruby orientated. We
could have refactored it even more, but wanted the initial release to retain as much of the original code as possible.

Please enjoy, this is a great MUD and its history deserves to be retained and the code "lived in".

- [MangledMe](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)
- [Alexander Morrow](mailto:amo3@umbc.edu)

Trying it out
-------------

We are running a server at `f8f8ff.com` on port `2525`. You can try the MUD out by, say telnet'ing in to it: `telnet ip-address 2525` (you will need
to lookup the ip address). For documentation see the associated "Three's Unabridged Dictionary of Commands" - See [Documentation](#Documentation).

Install
-------

The code has been tested on Linux, Mac and Windows. For Linux and Mac we used `ruby 1.9.2p290` (through RVM) and `ruby 1.9.3-p125`
on windows with the associated dev. kit installed.

Pull the code from here, in the main directory:

    $ gem install bundler
    $ bundle install

Testing
-------

The code is *very well* tested (we achieved nearly 100% line/branch coverage of the original code via these tests).
The default rake task is to run the unit and regression tests:

    $ rake

Ignore the various stdout/stderr messages, these are "original" informal output. There are also some networking tests, to run them you need to
start the mud server and then execute the tests, e.g.:

    $ ruby ./lib/mud.rb -d minimal.db -o dump

In another terminal (for example):

    $ ruby ./test/networking_test.rb

If any of these tests break, panic (and if you wish e-mail/contact us).

Running
-------

To run the server, type:

    $ ruby ./lib/mud.rb -d minimal.db -o dump

You can also specify the port on which to run (the default is `4201`) and some other options, try `--help`. Two (original, in format and content) database's are provided:

* `minimal.db` : A tiny database, containing, well the minimal amount!
* `small.db` : A slightly larger database

To connect, launch `telnet (localhost 4201)`, for example, or use a more advanced client such as [TinTin++](http://tintin.sourceforge.net/index.php). You should
be greeted with some text, e.g.:

    Welcome to MangledMUD
    To connect to your existing character, enter "connect name password"
    To create a new character, enter "create name password"
    Use the news command to get up-to-date news on program changes.

    You can disconnect using the QUIT command, which must be capitalized as shown.

    Use the WHO command to find out who is currently active.

The Wizard player is always defined, you connect as them by typing (assumming an original database):

    > connect wizard potrzebie

The password of [potrzebie](https://en.wikipedia.org/wiki/Potrzebie) has some associated history.

<a id="Documentation"/>Documentation
-----------------------

We have converted the original "Three's Unabridged Dictionary of Commands", if you `rake doc:yard` you will get local documentation (under `doc`) and this [link](./file.guide.html) will work, or via GitHub click on [guide.md](../guide.md) to browse the markdown source in the git repository.

Version
-------

We chose to port [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD) version `1.4.1`. This is a fairly early edition, it lacks some of the later incarnations
features. This specific version was chosen as it had the least code pollution, later versions were filled with `#define`'s. We believe
that it would be a simple step to port specific commands now that the code is in place - Through diff'ing the changes to the original and applying
the desired functionality. Source code for later versions may be found [here](http://www.mudbytes.net/) (under code repository `/Tiny`, version `1.5.4(f)`).

The git repository contains the original source, updated to compile with a modern gcc, it was removed before release in commit `d3601f7d2a7c598ce1dcd87fde1cd9931556d2e2`. Resurrecting it should be easy.

Enhancements
------------

There are a number of possible enhancements:

* Refactoring the database from in-memory to some kind of true database. Note that the unit tests are slightly fragile wrt the database, this would also need attention.
* During the port we shifted the majority of strings into a "phrasebook", localization would also now be trivially possible.
* Because of the database structure the networking code is non-threaded, it handles each request in turn. It would be nice to see the networking improved,
neither of us are experts in this area and we are pretty sure its not as robust as it could be :-)
* It would be good to see the code extended to support the full command set (see above).
* Keep refactoring the code to make it more ruby like.

If you wish to extend this then please maintain the high level of unit test coverage. We only request that the master branch progresses along the lines
of the original, even if it's innards are replaced entirely it should still run like the original and support importing original database files.

Fancy helping port a MUD?
-------------------------

We have been bitten by this exercise and are considering porting the [LambdaMoo](https://en.wikipedia.org/wiki/LambdaMOO) or a later variant of TinyMud,
e.g. [TinyMUCK](https://en.wikipedia.org/wiki/TinyMUCK) - Possibly using ruby as the internal language. MUD code is very interesting and the academic
exercise of porting to a different language whilst retaining a high level of confidence the code runs as intended is fun (may-be we are odd :-)). Lastly
the end result keeps some history alive and helps ensure future generations will be able to run these programs.

If you are interested and would like to help then please contact [me](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)

License
-------

Before putting the code on GitHub we complied with the original license and received a blessing from [James Aspnes](https://en.wikipedia.org/wiki/James_Aspnes).

We would ask that any further development also follows the intent of the original license by crediting the original author(s) and making sure that the source is marked as derived from [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD). A copy of the original license is kept in the repository in the file `tinymud_copyright`.
