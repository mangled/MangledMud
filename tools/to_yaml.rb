# Simple utility to dump TinyMUD formatted databases to YAML - Input can be a file, or via stdin
# e.g. ruby to_yaml.rb file.db, or ruby to_yaml.rb < file.db, or even cat ../db/minimal.db | ruby to_yaml.rb
require 'yaml'
require_relative '../lib/db'

if __FILE__ == $0
    db = MangledMud::Db.new()
    db.load(StringIO.new(ARGF.read))
    $stdout.binmode
    $stdout.puts(YAML::dump(db))
end
