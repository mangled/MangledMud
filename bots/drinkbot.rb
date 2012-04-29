# A simple bot for the flat.db database and the launch party.
#
# ** This bot assumes the existance of a player: drinkbot2000 slaveforyou
# ** and that this player is a wizard.
#
# i.e. login, create drinkbot2000 slaveforyou
# as a wizard @find drinkbot2000, @set #nnn=WIZARD, give #nnn=1 (need at least one penny for rob failure)
#
require 'yaml'
require 'net/telnet'
require 'ostruct'
require_relative 'util'
require_relative '../test/player.rb'

################################################################################
class DrinkBot

  def initialize(session, name, password, phrases, location = nil)
    @name = name
    @session = session
    @phrases = phrases
    @served_players = []
    connect(session, name, password, location)
    setup(session)
  end

  def act()
    begin
      parse_input(@session.waitfor('Timeout' => 1, 'Match' => /serve\s+\w+/))
    rescue Timeout::Error
      @served_players.each do |player|
        if rand(0) > 0.8
          do_substance(player)
          player.substance_turns_left = player.substance_turns_left - 1
          if player.substance_turns_left <= 0
            puts "#{player.name} is normal again."
            @session.write("@force #{player.name}=:feels normal\r\n")
            @served_players.delete(player)
          end
        end
      end
    end
  end

  def do_substance(player)
    puts "#{player.name} is behaving oddly #{player.substance_turns_left - 1} turns left"
    type = player.substance
    if rand(0) <= 0.5
      @session.write("@force #{player.name}=:#{@phrases[(type.to_s + "_do").intern].sample % player.substance_description}\r\n")
    else
      @session.write("@force #{player.name}=say #{@phrases[(type.to_s + "_say").intern].sample % player.substance_description}\r\n")
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
    session.cmd('@describe me=A state of the art drinks serving machine. Just "say serve command", where command is either "help" or a command and I will obey. Beep.')
    session.cmd('@lock me=me')
    session.cmd('@fail me=Your name has been noted. Beep.')
    session.cmd('@ofail me=tried to rob the drinkbot2000')
  end

  def parse_input(outstanding_text)
    # This is pretty much the event loop. I would like it to sleep then say a few words, like drink's on sale
    outstanding_text.each_line do |line|
      if line =~ /\s*(.*)\s+says\s+\"serve\s+(\w+).*\"/  # e.g. Wizard says "serve beer"
        case $2
          when 'help' then @session.cmd('say Beep. Drinkbot2000 commands are "help", "beer", "wine", "pill" and "food". Beep')
          when 'pill' then serve($1, :pill)
          when 'beer' then serve($1, :beer)
          when 'wine' then serve($1, :wine)
          when 'food' then serve($1, :food, false)
          else
            @session.cmd("say Sorry I do not understand the command \"#{$2}\". Beep.")
        end 
      end
    end
  end

  def serve(name, type, say_type = true)
    location = Utilities.look(@session)
    person_to_serve = location.players.find {|player| player.name == name }
    if @served_players.find {|player| player.id == person_to_serve.id }
      @session.cmd("say You haven't finished your current serving yet. Beep.")
    else
      puts "Serving #{name} a #{type}"
      person_to_serve.substance = type
      person_to_serve.substance_description = @phrases[(type.to_s + "_descriptions").intern].sample
      person_to_serve.substance_turns_left = 3 + rand(2)
      @served_players << person_to_serve
      if say_type
        @session.cmd(":hands #{person_to_serve.name} a #{person_to_serve.substance_description} #{type.to_s}")
      else
        @session.cmd(":hands #{person_to_serve.name} a #{person_to_serve.substance_description}")
      end
      @session.cmd(":Enjoy. Beep.")
    end
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

  puts "Loading drinkbot phrases..."
  phrases = YAML.load_file(File.join(File.dirname(__FILE__), 'drinkbot.yml'))

  NAME     = "drinkbot2000"
  PASSWORD = "slaveforyou"
  LOCATION = 27 # The living room

  puts "Drinkbot client starting on #{host}:#{port}"
  session = Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => Regexp.new(">done<"))

  drinkbot = DrinkBot.new(session, NAME, PASSWORD, phrases, LOCATION)
  while true
    drinkbot.act()
  end

  # will never be hit!
  puts "Exiting now..."
  session.cmd('QUIT')

  session.close()
end
################################################################################
