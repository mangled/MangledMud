require 'db'
require 'pp'

# Todo:
# /* special dbref's */ See db.h
# Want to set flags e.g. class const's - How
# Db free!
# This should be a test?

# Extend DB?
def print(record) # to_s?
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
	puts "Type: #{record.type}"
	puts "Desc: #{record.desc}"
	puts "Flgs: #{record.flags}"
	puts "Pwd : #{record.password}"
end

db = TinyMud::Db.new
puts "Length: #{db.length}"
db.add_new_record
puts "Length: #{db.length}"

record = db.get(0)

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

db.put(0, record)
print(db.get(0))

# READ!!!!
puts "Reading file..."
db.read("minimal.db")
puts "Read file... #{db.length} entries found"
for i in 0..(db.length - 1)
	puts "Record #{i}"
	puts "-----------"
	print(db.get(i))
	puts
end

