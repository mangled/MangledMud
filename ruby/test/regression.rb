# Todo: This will handle producing regression code
require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'pp'

module TinyMud
    class TestRegression < Test::Unit::TestCase
        
        def cmd_files
            Dir.glob("./commands/*.cmd")
        end
        
        def pass_file(cmd_file)
            Dir.glob(cmd_file.gsub(".cmd", ".pass"))
        end
        
        def collect_responses(content)

            players = { "wizard" => 1 }
            game = TinyMud::Game.new

            result = []
            
            Interface.set_out(result)
            
            content.each do |line|
                if line !~ /^\s*#/ # Skip comments
                    if line =~ /^\s*!(.*)/ # Is a special command line?
                        cmds = $1.split(' ')
                        if cmds[0] == "create_player"
                            result << "Creating player: \"#{cmds[1]}\" with password \"#{cmds[2]}\"\n"
                            players[cmds[1]] = TinyMud::Player.new.create_player(cmds[1], cmds[2])
                        end
                    elsif line =~ /^(\w+)>(.*)/
                        player = $1
                        command = $2.strip
                        raise "Unkown player: \"#{player}\"" unless players.has_key?(player)
                        result << "\e[32;1m#{player}(#{players[player]}): #{command}\e[0m\n"
                        game.process_command(players[player], command)
                    elsif line.strip.length != 0
                        result << "Failed parsing line: #{line}\n"
                    end
                end
            end
            
            result
        end

        def test_process_command_regressions
            class << Interface
                alias_method :old_do_notify, :do_notify

                def Interface.set_out(out)
                    @out = out
                end
        
                def do_notify(player, message)
                    @out << "\t\e[31;1m#{player} #{message}\e[0m\n"
                end
            end

            Interface.expects(:do_emergency_shutdown).never

            cmd_files().each do |cmd_file|
                db = TinyMud::Db.new
                Db.Minimal()
                current_result = open(cmd_file) {|content| collect_responses(content) }
                tmp_file = cmd_file.gsub(".cmd", ".tmp")
                open(tmp_file, "w") {|file| file.write(current_result.join)}
                pass_file = pass_file(cmd_file)
                if pass_file.length == 0
                    raise "Missing pass file for #{cmd_file}"
                else
                    diff = `diff #{pass_file} #{tmp_file}`
                    puts diff unless $? == 0
                end
                File.delete(tmp_file)
                db.free()
            end

            class << Interface
                  alias_method :get, :old_do_notify
            end
        end
    end
end


