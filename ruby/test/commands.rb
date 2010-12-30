# Todo: This will handle producing regression code
require 'rubygems'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

# Override Interface's do notify message to pick up and print messages
module TinyMud
    class << Interface
        alias_method :old_do_notify, :do_notify

        def do_notify(player, message)
            puts "\t\e[31;1m#{player} #{message}\e[0m"
        end
    end
end

if __FILE__ == $0
    if ARGV.length != 1
        puts "Usage: input_file"
        exit(-1)
    end
    
    db = TinyMud::Db.new
    TinyMud::Db.Minimal() # Gives us a location (limbo 0) and a wizard (1)

    players = { "wizard" => 1 }

    game = TinyMud::Game.new
	TinyMud::Interface.expects(:do_emergency_shutdown).never

    open(ARGV[0]) do |file|
        file.each do |line|
            if line !~ /^\s*#/ # Skip comments
                if line =~ /^\s*!(.*)/ # Is a special command line?
                    cmds = $1.split(' ')
                    if cmds[0] == "create_player"
                        puts "Creating player: \"#{cmds[1]}\" with password \"#{cmds[2]}\""
                        players[cmds[1]] = TinyMud::Player.new.create_player(cmds[1], cmds[2])
                    end
                elsif line =~ /^(\w+)>(.*)/
                    player = $1
                    command = $2.strip
                    raise "Unkown player: \"#{player}\"" unless players.has_key?(player)
                    puts "\e[32;1m#{player}(#{players[player]}): #{command}\e[0m"
                    game.process_command(players[player], command)
                elsif line.strip.length != 0
                    puts "Failed parsing line: #{line}"
                end
            end
        end
    end
end
