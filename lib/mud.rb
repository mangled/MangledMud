#!/usr/bin/env ruby
require_relative 'constants'
require_relative 'options'
require_relative 'db'
require_relative 'game'
require_relative 'server'
require_relative 'dump'

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
  dump = MangledMud::Dump.new(db, options[:dumpfile])
  server = Server.new(options[:host], options[:port], dump)
  game = MangledMud::Game.new(db, dump, "help.txt", "news.txt")
  server.run(db, game)

  game.dump_database()
  exit(0)
end
