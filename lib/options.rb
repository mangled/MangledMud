#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require_relative 'constants'

module MangledMud
  
  # Handles command line option parsing
  #
  # @version 1.0
  # @see mud.rb
  class MudOptions

    # Create and return the default option set
    # @return [Hash] Default options and their values
    def MudOptions.default
      options = {}
      options[:database] = nil
      options[:dumpfile] = nil
      options[:port] = DEFAULT_PORT
      options[:host] = DEFAULT_HOST
      options[:helpfile] = "help.txt"
      options[:newsfile] = "news.txt"
      options
    end

    # Parse an array of command line arguments, if successfull return the options, else show help
    # and exit()!
    #
    # @param [Array] args The command line arguments to parse
    # @return [Hash] The options parsed and/or defaulted
    def MudOptions.get_options(args)
      options = MudOptions.default

      opts = OptionParser.new do |o|
        o.banner = "MangledMud - A ruby port of TinyMUD"
        o.separator ""
        o.on("-d DATABASE", "--database DATABASE", String, "Database to load") {|u| options[:database] = u }
        o.on("-o DUMPFILE", "--dumpfile DUMPFILE", String, "Dump file name") {|u| options[:dumpfile] = u }
        o.on("-p PORT", "--port PORT", Integer, "Port number") {|n| options[:port] = n }
        o.on("-t HOST", "--host HOST", String, "Hostname") {|u| options[:host] = u }
        o.on("-i HELPFILE", "--info HELPFILE", String, "Mud in-game help file name") {|u| options[:helpfile] = u }
        o.on("-n NEWSFILE", "--news NEWSFILE", String, "Mud in-game news file name") {|u| options[:newsfile] = u }
        o.on_tail("-h", "--help", "Show this message") do
          puts o
          exit(0)
        end
      end

      begin
        opts.parse!(args)
        unless options[:database] and options[:dumpfile]
          raise RuntimeError, "You must specify a database (-d) and a dumpfile (-o).\nTry -h or --help for more information."
        end
        raise RuntimeError, "Database file not found at: #{options[:database]}" unless File.exists?(options[:database])
        raise RuntimeError, "Help file not found at: #{options[:helpfile]}" unless File.exists?(options[:helpfile])
        raise RuntimeError, "News file not found at: #{options[:newsfile]}" unless File.exists?(options[:newsfile])
      end

      options
    end
  end
end
