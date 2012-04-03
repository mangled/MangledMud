#!/usr/bin/env ruby
require_relative 'constants'
require_relative 'options'
require_relative 'db'
require_relative 'game'
require_relative 'server'
require_relative 'dump'

# Main cmd line entry for MangledMUD
if __FILE__ == $0
  # Parse options
  options =
    begin
      MangledMud::MudOptions.get_options(ARGV)
    rescue RuntimeError => e
      puts e
      exit(-1)
    end

  # Create a new database in memory and populate it with the content
  # of the database file provided on the command line.
  database = options[:database]
  db = MangledMud::Db.new()
  puts "LOADING: #{database}"
  db.load(database)
  puts "LOADING: #{database} (done)"

  # Start the server
  server = Server.new(options[:host], options[:port])
  puts "Server started at #{options[:host]} on port #{options[:port]}"

  # Bind the game object to the server
  puts "Dumping to: #{options[:dumpfile]}"
  puts "Using help file: #{options[:helpfile]}"
  puts "Using news file: #{options[:newsfile]}"
  game = MangledMud::Game.new(db, options[:dumpfile], options[:helpfile], options[:newsfile])

  # Run until wizard shuts down or a "stop" signal occurs...
  server.run(db, game)

  # Ensure the current database content is dumped
  game.dump_database()

  exit(0)
end
