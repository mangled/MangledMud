TinyMud
=======

Picture from Blog

This repository archives the source for [TinyMUD 1.4.1](http://en.wikipedia.org/wiki/TinyMUD) - In a compilable form. 
I have placed it under GitHub because finding the source is getting quite hard and when found the code isn't compilable.

Secondly, I'm writing a Ruby port/version built up by unit testing the original "C" code through Ruby extensions. This is
a painful process as I have to get a mass of code tested before I can ease in Ruby equivalents.

Yes, "I'm Mad!" - I really like the idea of the port being as true to the original as possible and because it grows from the
tests it sort of is related. Although this is going to produce some very non-Ruby style code for the first version.

So far, there has been a huge temptation to modify the old code once I have reasonable tests for it.

If you like "old" MUD's and computing history then I really could do with some help ;-) When completed it should be able to
read and function with original TinyMUD database files, it will also serve as the starting point for implementing further features
possibly those added in later versions. I went for 1.4.1 because it was small and had few hacks, later source's were crammed with
"#define's" and looked too difficult to tame.

I have tagged the 1.4.1 code (post my clean-up to get it compiling). The ruby port is on a branch "ruby-port". The original copyright
stands (and is included). If I complete this exercise I think it proper to try to inform David Applegate, James Aspnes and Bennet Yee
of this new work, as requested in the copyright terms.

If anyone would like me to host the original code on a server for some classic MUD sessions, then just shout!
