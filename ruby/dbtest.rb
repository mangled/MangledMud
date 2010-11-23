require 'db'
require 'pp'

# This should be a unit test?
db = TinyMud::Db.new
puts "Length: #{db.length}"
db.add_new_record
puts "Length: #{db.length}"

record = db.record(0)
puts "Name: #{record.name}"
puts "Desc: #{record.description}"
puts "Loc.: #{record.location}"
puts "Con.: #{record.contents}"
puts "Exts: #{record.exits}"
puts "Next: #{record.next}"
puts "Key : #{record.key}"
puts "Fail: #{record.fail}"
puts "Succ: #{record.succ}"
puts "OFai: #{record.ofail}"
puts "OSuc: #{record.osucc}"
puts "Ownr: #{record.owner}"
puts "Pens: #{record.pennies}"
puts "Flgs: #{record.flags}"
puts "Pwd : #{record.password}"

# FIXME: This isn't actually altering the underlying database!!!!
# Make a new struct which has the record ptr and the "at" value
# Pain but simple enough
record.name = "name"
record.description = "description"
record.location = 0
record.contents = 1
record.exits = 2
record.next = 3
record.key = 4
record.fail = "fail"
record.succ = "succ"
record.ofail = "ofail"
record.osucc = "osucc"
record.owner = 5
record.pennies = 6
record.flags = 7
record.password = "password"

puts
puts "Name: #{record.name}"
puts "Desc: #{record.description}"
puts "Loc.: #{record.location}"
puts "Con.: #{record.contents}"
puts "Exts: #{record.exits}"
puts "Next: #{record.next}"
puts "Key : #{record.key}"
puts "Fail: #{record.fail}"
puts "Succ: #{record.succ}"
puts "OFai: #{record.ofail}"
puts "OSuc: #{record.osucc}"
puts "Ownr: #{record.owner}"
puts "Pens: #{record.pennies}"
puts "Flgs: #{record.flags}"
puts "Pwd : #{record.password}"

