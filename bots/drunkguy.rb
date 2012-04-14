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

# TODO: put in a class?
# - tidy up and document
# - add more phrases
# - make robust (is there anything anyone else can do to muck it up?)
# - always start in limbo (rename this anyway) teleport to #0

def connect(session, name, password)
  session.waitfor(/currently active\./)
  session.write("connect #{NAME} #{PASSWORD}\r\n")
  session.cmd('String' => "OUTPUTPREFIX prefix", 'Match' => /Done/)
  session.cmd('String' => "OUTPUTSUFFIX >done<", 'Match' => /Done/)
  # start at #0
  session.write("@TELEPORT me=#0\r\n")
end

def setup(session, bottle_phrases)
  session.cmd('@describe me=A lover of all things alcholic, hic.')
  unless session.cmd('@FIND bottle').lines.find {|line| line =~ /bottle/}
    session.cmd('@CREATE bottle')
  end
  session.cmd('@FIND bottle')=~ /\s+bottle\s*\(#(\d+)\)/
  bottle_id = $1
  session.write("@TELEPORT ##{bottle_id}=me\r\n")
  session.cmd("@LOCK ##{bottle_id}=me")
  session.cmd("@DESCRIBE ##{bottle_id}=A bottle")
  session.cmd("@OSUCCESS ##{bottle_id}=#{bottle_phrases.sample}")
  session.cmd("@LINK ##{bottle_id}=me")
  bottle_id
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
  here = session.cmd('examine here')
  m = /Contents:(.*)Exits:(.*)/m.match(here)
  if m
    extract_item(session, m[1], /Type: Player/) {|name, id| players[name] = id }
    extract_item(session, m[2], /Destination: .*?\(\#(\d+)\)/) {|name, id| exits[name.partition(';')[0]] = id }
  end
  [players, exits]
end

def swear(session, insults, players)
  insult = insults.sample
  session.cmd("say #{insult % players.keys.sample}")
  sleep(1)
  insult
end

def drop_and_pickup_bottle(session, bottle_id, pre, post)
  session.cmd("say #{pre.sample}")
  sleep(1)
  session.cmd("drop ##{bottle_id}")
  sleep(1 + rand(2))
  session.cmd("take ##{bottle_id}")
  sleep(1)
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
  
  puts "Drunk guy starting on #{host}:#{port}"
  session = Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => Regexp.new(">done<"))

  connect(session, NAME, PASSWORD)
  bottle_id = setup(session, phrases[:bottle_osucc])

  in_toilet = false
  while true
    players, exits = contents(session)

    if exits.length == 0
      puts "Failed to find an exit! - stopping"
      session.close()
      exit(-1)
    end

    # todo - store previous room's and don't consider a move back to them
    # unless they are the only option. Movement is a bit pants!!!
    do_move = rand(0) > 0.6
    if do_move
      # Don't go to the toilet via a move.
      next_exit = exits.keys.reject {|e| e.include?('toilet') }.sample
      if next_exit

        puts "Moving to: #{next_exit}"

        session.cmd("say #{phrases[:leaving].sample}")
        loc = session.cmd("move #{next_exit}")
        if loc =~ /(.* \(#\d+\))/
          puts "Now at: #{$1}"
        end

        # It doesn't matter if they have moved into the toilet
        # just won't emit silly phrases once in a while.
        in_toilet = false
      end
    elsif rand(0) > 0.98 and not in_toilet
      puts "Moving directly to the toilet"
      go_toilet(session, phrases[:toilet])
      in_toilet = true
      last_exit = nil
    end

    session.cmd("@OSUCCESS ##{bottle_id}=#{phrases[:bottle_osucc].sample}") if rand(0) > 0.95 # put in drop bottle
    swear(session, phrases[:mutterings], players.reject {|player| player.include?(NAME) }) if rand(0) > 0.6
    drop_and_pickup_bottle(session, bottle_id, phrases[:bottle_pre], phrases[:bottle_post]) if rand(0) > 0.9
    session.cmd(":#{phrases[:before_sleep].sample}") if rand(0) > 0.7

    sleep(3 + rand(1))
  end

  puts "Exiting now..."
  session.cmd('QUIT')

  session.close()
end
