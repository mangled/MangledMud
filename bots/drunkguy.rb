# A simple bot for the flat.db database and the launch party.
#
# ** This bot assumes the existance of a player: drunk_guy steaming_person
# ** and that this player is a wizard.
#
# i.e. login, create drunk_guy steaming_person
# as a wizard @find drunk_guy, @set #nnn=WIZARD
#
require 'yaml'
require 'net/telnet'
require 'ostruct'
require_relative 'util'
require_relative '../test/player.rb'

################################################################################
class DrunkGuy

  def initialize(session, name, password, phrases, toiletid, other_nogos, start_location = nil)
    @name = name
    @session = session
    @phrases = phrases
    @toiletid = toiletid
    connect(session, name, password, start_location)
    @in_toilet = start_location == toiletid
    @bottleid = setup(session, phrases[:bottle_osucc])
    @map = Map.new(session, other_nogos << toiletid)
    reset_bladder()
  end

  def act(movement_allowed = true)
    if needs_the_toilet? and movement_allowed
      puts "Going to the toilet!"
      go_toilet()
      @map.update_location()
    elsif rand(0) > 0.8 and movement_allowed
      @session.cmd("say #{@phrases[:leaving].sample}")
      @map.pick_next_exit()
      @in_toilet = false
    else
      @map.update_location()
      @bottles_drunk = @bottles_drunk + 1 if rand(0) > 0.5
      puts "Bladder full" if (needs_the_toilet? and movement_allowed)
      available_players = @map.location.players.reject {|player| player.name == @name }
      swear_someone(available_players) if rand(0) > 0.7
      drop_and_pickup_bottle() if (rand(0) > 0.95 and available_players.length != 0)
      @session.cmd(":#{@phrases[:before_sleep].sample}") if rand(0) > 0.7
    end
  end

  private

  def connect(session, name, password, start_location = nil)
    session.waitfor('Match' => /currently active\./)
    session.write("connect #{NAME} #{PASSWORD}\r\n")
    session.cmd('String' => "OUTPUTPREFIX prefix", 'Match' => /Done/)
    session.cmd('String' => "OUTPUTSUFFIX >done<", 'Match' => /Done/)
    session.write("@TELEPORT me=##{start_location}\r\n") if start_location
    session.cmd('look')
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

  def swear_someone(players)
    unless players.empty?
      player_name = players.sample.name
      puts "Swearing at #{player_name}"
      insult = @phrases[:mutterings].sample
      @session.cmd("say #{insult % player_name}")
      sleep(1 + rand(3))
    end
  end
  
  def drop_and_pickup_bottle()
    puts "Dropping and picking up bottle"
    @session.cmd("say #{@phrases[:bottle_pre].sample}")
    sleep(2)
    @session.cmd("drop ##{@bottleid}")
    sleep(1 + rand(2))
    @session.cmd("take ##{@bottleid}")
    sleep(2)
    @session.cmd("say #{@phrases[:bottle_post].sample}")
    # Change the success on bottle pick up
    @session.cmd("@OSUCCESS ##{@bottleid}=#{@phrases[:bottle_osucc].sample}")
  end

  def go_toilet()
    @session.cmd("@teleport me=##{@toiletid}")
    reset_bladder()
    @session.cmd("say #{@phrases[:toilet].sample}")
    sleep(1 + rand(2))
  end

  def needs_the_toilet?
    (@bottles_drunk >= @bladder_size) and not @in_toilet
  end

  def reset_bladder
    @bottles_drunk = 0
    @bladder_size = 5 + rand(10)
    @in_toilet = true
  end
end

################################################################################
class Map

  attr_accessor :location

  def initialize(session, nogos)
    @session = session
    @nogos = nogos
    @visit_count = Hash.new(0)
    @last_location_id = nil
    @location = Utilities.look(@session)
  end

  def update_location()
    @location = Utilities.look(@session)
  end

  def pick_next_exit()
      # Look at current location
      @location = Utilities.look(@session)
      raise "Failed to find an exit at #{@location.name}!" if @location.exits.length == 0

      # Reject any exits in the no-go list
      exits = @location.exits.reject{|exit| @nogos.include?(exit.destid.to_i) }

      # Reject any circular (bogus exits)
      exits = exits.reject{|exit| exit.destid == @location.id }

      # Lastly we want only exits that lead away from this room, but it might be a dead end
      go_back_exits = exits.find_all{|exit| exit.destid == @last_location_id }
      go_elsewhere_exits = exits.find_all{|exit| exit.destid != @last_location_id }

      # Now opt to go somewhere else, if possible
      if go_elsewhere_exits.length > 0
        exits = go_elsewhere_exits
      else
        exits = go_back_exits
      end

      # Collect potential destinations and order by visit count (low to high)
      order_of_visit = exits.collect {|exit| [exit, @visit_count[exit.destid]] }.sort {|a, b| a[1] <=> b[1] }

      # Take all the lowest (equal) visit counted exits and pick one
      chose = order_of_visit.take_while {|i| i[1] == order_of_visit[0][1] }.sample()

      # If we fail to find any exit then the room is one way so start at zero
      @last_location_id = @location.id
      unless chose
        puts "Failed to find an exit in exits #{exits}, so going back to #0"
        puts "Was at #{@last_location_id}"
        puts "Location #{@location.name} ##{@location.id} exits"
        @location.exits.each do |exit|
          puts "\tExit #{exit.name} ##{exit.id} dest #{exit.destid}"
        end
        @session.write("@TELEPORT me=##{0}\r\n")
      else
        # Update visit count, record chosen exit and move
        @visit_count[chose[0].destid] = chose[1] + 1
        puts "Moving to: #{chose[0].destname} (##{chose[0].destid})"
        @session.cmd("move #{chose[0].name}")
      end

      # finally make sure our location is up to date
      @location = Utilities.look(@session)
  end
end

################################################################################
if __FILE__ == $0
  host = ARGV[0]
  port = ARGV[1]
  if (!host or !port)
    puts "host and/or port required."
    exit(-1)
  end

  puts "Loading drunken phrases..."
  phrases = YAML.load_file(File.join(File.dirname(__FILE__), 'drunkguy.yml'))

  NAME     = "drunk_guy"
  PASSWORD = "steaming_person"
  TOILET   = 89
  TO_WINDOW = 130 # window ledge from bathroom
  START_LOCATION = 201#146

  puts "Drunk guy client starting on #{host}:#{port}"
  session = Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => Regexp.new(">done<"))

  drunkguy = DrunkGuy.new(session, NAME, PASSWORD, phrases, TOILET, [TO_WINDOW], START_LOCATION)
  while true
    drunkguy.act()
    sleep(1 + rand(4))
  end

  # will never be hit!
  puts "Exiting now..."
  session.cmd('QUIT')

  session.close()
end
################################################################################