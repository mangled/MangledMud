# Todo: This will handle producing regression code
require 'rubygems'
require 'test/unit'
require 'mocha'
require 'defines'
require 'tinymud'
require 'commands'
require 'pp'

module TinyMud
    
    class TestRegression < Test::Unit::TestCase
        
        def cmd_files
            Dir.glob("./commands/*.cmd")
        end
        
        def pass_file(cmd_file)
            Dir.glob(cmd_file.gsub(".cmd", ".pass"))
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


