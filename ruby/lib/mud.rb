require_relative 'constants'
require_relative 'db'
require_relative 'game'
require_relative 'server'

# Main cmd line entry for the MUD
if __FILE__ == $0
    if (ARGV.length < 2) or (ARGV.length > 3)
        puts "Usage: infile dumpfile [port]"
        exit(-1)
    end

    database, dumpfile, port = ARGV
    port = TinyMud::DEFAULT_PORT unless port

    db = TinyMud::Db.new()
    puts "LOADING: #{database}"
    db.load(database)
    puts "LOADING: #{database} (done)"

    server = Server.new("localhost", port)
    game = TinyMud::Game.new(db, dumpfile, "help.txt", "news.txt", server, lambda { server.close_sockets() })

    server.run(db, game)

    game.dump_database()
    exit(0)
end
