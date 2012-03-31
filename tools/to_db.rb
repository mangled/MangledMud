# Simple utility to dump TinyMUD yaml formatted databases to a TinyMUD database format
# Input can be a file, or via stdin
# e.g. ruby to_db.rb foo.yaml, or ruby to_db.rb < foo.yaml, or even cat foo.yaml | ruby to_db.rb
require 'yaml'
require_relative '../lib/db'

if __FILE__ == $0
  db = YAML.load(ARGF.read)
  $stdout.binmode
  db.save($stdout)
end
