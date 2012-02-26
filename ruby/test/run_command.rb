# This allows you to run any of the regression scripts in "commands"
# The "unit test" regression.rb calls all of the commands and diffs
# against expected. This is "ok" once you are happy with a test script.
# During development its easier to see the output, hence this tiny script
require 'rubygems'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'commands'

if __FILE__ == $0
    if ARGV.length != 1
        puts "Please enter a script name (look under commands/*.cmd)"
        exit(-1)
    end
    
    cmd_file = ARGV[0]
    unless File.exists?(cmd_file)
        puts "Cannot find #{cmd_file}"
        exit(-1)
    end
    
    # Go!
    db = TinyMud::Db.Minimal()
    open(cmd_file) {|content| TinyMud::CommandHelpers.collect_responses(db, "not used", content) }.each{|line| puts line }
end
