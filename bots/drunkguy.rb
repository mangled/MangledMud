# An experiment at making a simple bot for the flat.db and the
# launch party.
#
# ** This bot assumes the existance of a player: drunk_guy steaming_person
# ** and that this player is a wizard.
#
# i.e. login, create drunk_guy steaming_person
# as wizard @set drunk_guy=WIZARD
#
# THIS IS WIP
require 'yaml'
require 'net/telnet'
require_relative '../test/player.rb'

# REMOVE
require 'pp'

# TODO: put in a class?
# - tidy up and document
# - add more phrases
# - make robust (is there anything anyone else can do to muck it up?)
# - always start in limbo (rename this anyway) teleport to #0
# - drop things, for non wizards, not seen! so add text.

# I'm drunk
# What's in my pocket
# scratches his crotch
# I like naked ladies!
# dark - feel, light
def connect(session, name, password)
  session.waitfor(/currently active\./)
  session.write("connect #{NAME} #{PASSWORD}\r\n")
  session.cmd('String' => "OUTPUTPREFIX prefix", 'Match' => /Done/) {|s| puts s}
  session.cmd('String' => "OUTPUTSUFFIX >done<", 'Match' => /Done/) {|s| puts s}
end

def setup(session)
  session.cmd('@describe me=A lover of all things alcholic, hic.')
  unless session.cmd('@FIND bottle').lines.find {|line| line =~ /bottle/}
    session.cmd('@CREATE bottle')
  end
  session.cmd('@FIND bottle')=~ /\s+bottle\s*\(#(\d+)\)/
  bottle_id = $1
  session.write("@TELEPORT ##{bottle_id}=me\r\n")
  session.cmd("@LOCK ##{bottle_id}=me")
  session.cmd("@DESCRIBE ##{bottle_id}=A bottle")
  session.cmd("@OSUCCESS ##{bottle_id}=swaggers and picks up a bottle.") # Consider changing this dynamically
  session.cmd("@LINK ##{bottle_id}=me")
end

def extract_item(session, s, type)
  m = s.scan(/\s*(.+)\(#(\d+)\)\s*/)
  m.each do |item|
    info = session.cmd("examine ##{item[1]}")
    yield item if info =~ type
  end
end

def contents(session)
  players = {}
  exits = {}
  m = /Contents:(.*)Exits:(.*)/m.match(session.cmd('examine here'))
  if m
    extract_item(session, m[1], /Type: Player/) {|name, id| players[name] = id }
    extract_item(session, m[2], /Destination: .*?\(\#(\d+)\)/) {|name, id| exits[name.partition(';')[0]] = id }
  end
  [players, exits]
end

def swear(session, insults, players)
  insult = insults.sample
  session.cmd("say #{insult % players.keys.sample}")
  insult
end

def drop_and_pickup_bottle(session, pre, post)
  session.cmd("say #{pre.sample}")
  session.cmd('drop bottle')
  sleep(1 + rand(2))
  session.cmd('take bottle')
  session.cmd("say #{post.sample}")
end

def go_toilet(session, messages)
  session.cmd('@teleport me=#89')
  sleep(1 + rand(2))
  session.cmd("say #{messages.sample}")
end

# This needs to be robust!!!
if __FILE__ == $0
  host = ARGV[0]
  port = ARGV[1]
  if (!host or !port)
    puts "host and/or port required."
    exit(-1)
  end

  puts "loading phrases..."
  phrases = YAML.load_file(File.join(File.dirname(__FILE__), 'drunkguy.yml'))

  NAME = "drunk_guy"
  PASSWORD = "steaming_person"
  
  puts "drunk guy starting on #{host}:#{port}"
  session = Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => Regexp.new(">done<"))

  connect(session, NAME, PASSWORD)
  setup(session)

  in_toilet = false
  while true
    players, exits = contents(session)

    do_move = rand(0) > 0.9
    if do_move
      next_exit = exits.keys.sample
      if next_exit
        session.cmd("say #{phrases[:leaving].sample}")
        session.cmd("move #{next_exit}")
        # It doesn't matter if they have moved into the toilet
        # just won't emit silly phrases once in a while.
        in_toilet = false
      else
        puts "No exit - shut me down!"
        session.close()
        exit(-1)
      end
    end

    swear(session, phrases[:mutterings], players.reject {|player| player.include?(NAME) }) if rand(0) > 0.8
    drop_and_pickup_bottle(session, phrases[:bottle_pre], phrases[:bottle_post]) if rand(0) > 0.8

    if rand(0) > 0.95 and not in_toilet
      go_toilet(session, phrases[:toilet])
      in_toilet = true
    end

    session.cmd(":falls asleep") if rand(0) > 0.7

    sleep(3 + rand(4))
  end

  puts "exiting now"
  session.cmd('QUIT')

  session.close()
end
