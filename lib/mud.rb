#!/usr/bin/env ruby
require_relative 'constants'
require_relative 'options'
require_relative 'db'
require_relative 'game'
require_relative 'server'

# Main cmd line entry for the MUD
if __FILE__ == $0
    options =
      begin
          MangledMud::MudOptions.get_options(ARGV)
      rescue RuntimeError => e
          puts e
          exit(-1)
      end

    database = options[:database]
    db = MangledMud::Db.new()
    puts "LOADING: #{database}"
    db.load(database)
    puts "LOADING: #{database} (done)"

    puts "Server started at #{options[:host]} on port #{options[:port]}"
    server = Server.new(options[:host], options[:port])

    game = MangledMud::Game.new(db, options[:dumpfile], "help.txt", "news.txt", server, lambda { server.close_sockets() })
    server.run(db, game)

    game.dump_database()
    exit(0)
end
