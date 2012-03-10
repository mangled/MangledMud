# Helpers for running "commands" regressions, used by run_command.rb
# and regression.rb
require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'

module TinyMud
    
    class Notifier
        def initialize(buffer)
            @buffer = buffer
        end

        def do_notify(player, message)
            @buffer << "\t\e[31;1m#{player} #{message}\e[0m\n"
        end
    end

    class CommandHelpers

        # Given db, find thing by name
        def CommandHelpers.find(db, name)
            for i in 0..(db.length - 1)
                return i if db[i].name == name
            end
            raise "Find #{name} failed!"
        end
        
        # Read content, apply commands to db
        def CommandHelpers.collect_responses(db, dumpfile, content)

            players = { "wizard" => 1 }

            result = []
            notifier = Notifier.new(result)
            game = TinyMud::Game.new(db, dumpfile, "help.txt", "news.txt", notifier)

            # Keep a track of dumped database files and delete them
            dumped_databases = []

            # Ensure we never give pennies and never manage to kill
			Game.stubs(:do_rand).returns(17)
            
            content.each do |line|
                if line !~ /^\s*#/ # Skip comments
                    if line =~ /^\s*!(.*)/ # Is a special command line?
                        cmds = $1.split(' ')
                        if cmds[0] == "create_player"
                            result << "Creating player: \"#{cmds[1]}\" with password \"#{cmds[2]}\"\n"
                            players[cmds[1]] = TinyMud::Player.new(db, notifier).create_player(cmds[1], cmds[2])
                        elsif cmds[0] == "@dump"
                            result << "Dumping database\n"
                            dumped_databases << 'cheese.dump'
                            Dump.new(db, nil).dump_database_internal(dumped_databases[-1])
                        elsif cmds[0] == "load"
                            result << "Reading database from: " << cmds[1] << "\n"
                            game = TinyMud::Game.new(db, dumpfile, "help.txt", "news.txt", notifier)
                            db.load(cmds[1])
                        end
                    elsif line =~ /^(\w+)>(.*)/
                        player = $1
                        command = $2.strip
                        raise "Unkown player: \"#{player}\"" unless players.has_key?(player)
                        result << "\e[32;1m#{player}(#{players[player]}): #{command}\e[0m\n"
                        # Replace #{name} with identifier - This makes the text tests more robust
                        # Can only handle one per line at present (all I need for now)
                        if command =~ /\{(.*?)\}/
                            what = $1
                            command.gsub!(/\{(.*?)\}/, "#{CommandHelpers.find(db, what)}")
                        end
                        game.process_command(players[player], command)
                    elsif line.strip.length != 0
                        result << "Failed parsing line: #{line}\n"
                    end
                end
            end

            # Remove any (temp.) dumped database files
            dumped_databases.each do |file|
                File.delete(file)
            end
            
            result
        end
        
    end
end
