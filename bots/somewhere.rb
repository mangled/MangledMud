# A "bot" which provides odd messages to a player in flat.db at location #225
# through forcing them through the bogus exit: #229
#
# ** This bot assumes the existance of a player: somewhere_bot veryweird1
# ** and that this player is a wizard.
#
# i.e. login, create somewhere_bot veryweird1
# as a wizard @find somewhere_bot, @set #nnn=WIZARD, @teleport #nnn=#180
#
require 'yaml'
require 'net/telnet'
require 'ostruct'
require_relative 'util'
require_relative '../test/player.rb'

require 'pp'

################################################################################
class Somewhere

  def initialize(session, name, password, location, locations)
    @name = name
    @session = session
    @locations = locations
    connect(session, name, password, location)
    setup(session)
  end

  def act()
    # For each location, look to see if there is a player present
    @locations.each do |location|
      location_details = Utilities.look(@session, "examine ##{location[:room]}")
      player = location_details.players.sample
      if player
        puts "Talking to player #{player.name} at #{location_details.name}(##{location_details.id})"
        @session.cmd("@fail ##{location[:exit_id]}=#{location[:phrases].sample}")
        @session.write("@force #{player.name}=#{location[:exit_name]}\r\n")
      end
      sleep(5 + rand(5))
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

  def setup(session)
    session.cmd('@lock me=me')
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

  puts "Loading somewhere locations..."
  locations = YAML.load_file(File.join(File.dirname(__FILE__), 'somewhere.yml'))

  NAME     = "somewhere_bot"
  PASSWORD = " veryweird1"
  LOCATION = 180 # secret hidy hole for locks

  puts "Somewhere client starting on #{host}:#{port}"
  session = Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => Regexp.new(">done<"))

  somewhere = Somewhere.new(session, NAME, PASSWORD, LOCATION, locations)
  while true
    somewhere.act()
  end

  # will never be hit!
  puts "Exiting now..."
  session.cmd('QUIT')

  session.close()
end
################################################################################