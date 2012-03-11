#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require_relative 'constants'

module MangledMud
    class MudOptions

        def MudOptions.default
            options = {}
            options[:database] = nil
            options[:dumpfile] = nil
            options[:port] = DEFAULT_PORT
            options[:host] = DEFAULT_HOST
            options
        end

        def MudOptions.get_options(args)
            options = MudOptions.default

            opts = OptionParser.new do |o|
                o.banner = "MangledMud - A ruby port of TinyMUD"
                o.separator ""
                o.on("-d DATABASE", "--database DATABASE", String, "Database to load") {|u| options[:database] = u }
                o.on("-o DUMPFILE", "--dumpfile DUMPFILE", String, "Dump file name") {|u| options[:dumpfile] = u }
                o.on("-p PORT", "--port PORT", Integer, "Port number") {|n| options[:port] = n }
                o.on("-t HOST", "--host HOST", String, "Hostname") {|u| options[:host] = u }
                o.on_tail("-h", "--help", "Show this message") do
                  puts o
                  exit(0)
                end
            end

            begin
                opts.parse!(args)
                unless options[:database] and options[:dumpfile]
                    raise RuntimeError, "You must specify a database (-d) and a dumpfile (-o).\nTry --h or --help for more information."
                end
            end

            options
        end
    end
end
