<img src="./mud.png" alt="MangledMud"/>

MangledMud 1.0
==============

MangledMud is a ruby port of [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD).

The port has been a labour of love and a painstaking exercise in testing! All of the original "C" code was wrapped in ruby extensions,
unit tests added, line coverage checked then ruby replacements implemented which matched the original's behaviour.
The full history of this port is held in the git repository, should you wish to delve.

In its present form it is structured almost as per the original and the code is still "C" rather than ruby orientated. We
could have refactored it even more, but wanted the initial release to retain as much of the original code as possible.

Please enjoy, this is a great MUD and its history deserves to be retained and the code "lived in".

- [MangledMe](http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=)
- [Alexander Morrow](http://www.google.com/recaptcha/mailhide/d?k=01n0PN-HG6h4hK6mVdmLzv9w==&c=kkuhcc5Ozzpy45FXpOqvJQ)

<a id="TryingItOut"/>Trying it out
-------------

We are running a server at `f8f8ff.com` on port `2525` and at `www.mangled.me` on port `4201`, for either try `telnet address port` or use something like [TinTin++](http://tintin.sourceforge.net/index.php) note that if you use TinTin++ please ensure that you set `{VERBATIM}  {ON}` otherwise semicolon separators will be treated as separate commands.

There is also a flash based interface to try in your web browser, go to http://www.mangled.me/mangledmud/. See [documentation](#Documentation) below for information on how to play the game.

As is usual with the internet, if you are reading this sometime in the future we cannot gaurantee to still be hosting these services.

Install
-------

The code has been tested on Linux, Mac and Windows (using [dev.](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit) kit) with `ruby 1.9.2p290`.

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

    $ ruby ./lib/mud.rb -d ./db/minimal.db -o dump

In another terminal:

    $ ruby ./test/networking_test.rb

If any of these tests break, panic (and if you wish e-mail/contact us).

Running
-------

To run the server, type:

    $ ruby ./lib/mud.rb -d ./db/minimal.db -o dump

You can also specify the port on which to run (the default is `4201`) and some other options, try `--help`. Two (original, in format and content) database's are provided (in the db folder):

* `minimal.db` : A tiny database containing the minimal amount!
* `small.db` : A slightly larger database

There is also another database designed for a small re-launch party:

* `flat.db`

To connect, see [Trying it out](#TryingItOut) above. You should be greeted with some text, e.g.:

    Welcome to MangledMUD
    To connect to your existing character, enter "connect name password"
    To create a new character, enter "create name password"
    Use the news command to get up-to-date news on program changes.

    You can disconnect using the QUIT command, which must be capitalized as shown.

    Use the WHO command to find out who is currently active.

The Wizard player is always defined, you connect as them by typing (assuming an original database):

    > connect wizard potrzebie

The password of [potrzebie](https://en.wikipedia.org/wiki/Potrzebie) has some associated history.

<a id="Documentation"/>Documentation
-----------------------

We have converted the original "Three's Unabridged Dictionary of Commands", if you `rake doc:yard` you will get local documentation (under `doc`) and this [link](./file.guide.html) will work, or via GitHub click on [guide.md](../guide.md) to browse the markdown source in the git repository.

The source code is also reasonably well documented, again `rake doc:yard` and look under `doc`

<a id="Version"/>Version
-------

We chose to port [TinyMUD](https://en.wikipedia.org/wiki/TinyMUD) version `1.4.1`. This is a fairly early edition, it lacks some of the later incarnations
features. This specific version was chosen as it had the least code pollution, later versions were filled with `#define`'s. We believe
that it would be a simple step to port specific commands now that the code is in place - Through diff'ing the changes to the original and applying
the desired functionality. Source code for later versions may be found [here](http://www.mudbytes.net/) (under code repository `/Tiny`, version `1.5.4(f)`).

Note that this version of the code will probably not handle slightly later database formats as a result of extensions to some of the commands, `@lock` for example.
If you are fortunate enough to have a later database and you wish to load it then please speak to us and we will look into addressing this.

The git repository contains the original source, updated to compile with a modern gcc, it was removed before release in commit `d3601f7d2a7c598ce1dcd87fde1cd9931556d2e2`. Resurrecting it should be easy.

Bots
----

We would have loved to incorporate one of the original chatter bots, but couldn't find any source. For the re-launch party we created some simple bots to spice things up. Look under `bots`, note these are very simple and fixed to the `flat.db` database.

Enhancements
------------

There are a number of possible enhancements:

* Refactoring the database from in-memory to some kind of true database. Note that the unit tests are slightly fragile wrt the database, this would also need attention.
* During the port we shifted the majority of strings into a "phrasebook", localization to other languages would now also be trivially possible.
* Because of the database structure the networking code is non-threaded, it handles each request in turn. It would be nice to see the networking improved,
neither of us are experts in this area and we are pretty sure its not as robust as it could be :-)
* It would be good to see the code extended to support the full command set (see [Version](#Version) above).
* Keep refactoring the code to make it more ruby like (we made some of it a little more object orientated, but held off a major re-write as this would defeat the point of the first release).

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
