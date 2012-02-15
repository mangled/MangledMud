# Todo: This will handle producing regression code
require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require_relative 'commands'

module TinyMud
    
    class TestRegression < Test::Unit::TestCase
        
        def cmd_files
            Dir.glob("./test/commands/*.cmd")
        end
        
        def pass_file(cmd_file)
            pass_file = Dir.glob(cmd_file.gsub(".cmd", ".pass"))
            assert_equal(1, pass_file.length)
            pass_file[0]
        end

        def test_process_command_regressions
            CommandHelpers.AliasInterface()

            cmd_files().each do |cmd_file|
                db = TinyMud::Db.new
                Db.Minimal()
                current_result = open(cmd_file) {|content| CommandHelpers.collect_responses(db, content) }
                tmp_file = cmd_file.gsub(".cmd", ".tmp")
                open(tmp_file, "w") {|file| file.write(current_result.join)}
                pass_file = pass_file(cmd_file)
                if pass_file.length == 0
                    raise "Missing pass file for #{cmd_file}"
                else
                    diff = `diff #{pass_file} #{tmp_file}`
                    unless $? == 0
                        puts diff
                    else
                        File.delete(tmp_file)
                    end
                end
                db.free()
            end

            CommandHelpers.DeAliasInterface()
        end
    end
end


