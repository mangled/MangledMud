require 'rubygems'
require 'test/unit'
require 'db'
require 'pp'

# These need to go into the TinyMud Module (ruby side)
TYPE_ROOM =	0x0
TYPE_THING = 0x1
TYPE_EXIT =	0x2
TYPE_PLAYER = 0x3
NOTYPE	= 0x7
TYPE_MASK = 0x7
ANTILOCK =	0x8
WIZARD = 0x10
LINK_OK	= 0x20
DARK = 0x40
TEMPLE = 0x80
STICKY = 0x100

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

module TinyMud
    class TestDb < Test::Unit::TestCase
		def setup
			@db = TinyMud::Db.new
		end

		def teardown
			@db.free()
		end

		def test_db_starts_empty
			assert_equal(0, @db.length)
		end
		
		def test_new_record
			@db.add_new_record
			assert_equal(1, @db.length)
		end
		
		def test_new_record_content
			@db.add_new_record
			record = @db.get(0)
			assert_equal(nil, record.name)
			assert_equal(nil, record.description)
			assert_equal(-1, record.location)
			assert_equal(-1, record.contents)
			assert_equal(-1, record.exits)
			assert_equal(-1, record.next)
			assert_equal(-1, record.key)
			assert_equal(nil, record.fail)
			assert_equal(nil, record.succ)
			assert_equal(nil, record.ofail)
			assert_equal(nil, record.osucc)
			assert_equal(-1, record.owner)
			assert_equal(0, record.pennies)
			# Flags is unitialized so methods which depend on it are unreliable
			assert_equal(nil, record.password)
		end
		
		def test_set_record_content
			@db.add_new_record
			record = @db.get(0)
			record.name = "name"
			assert_equal("name", record.name)
			record.description = "description"
			assert_equal("description", record.description)
			record.location = 0
			assert_equal(0, record.location)
			record.contents = 1
			assert_equal(1, record.contents)
			record.exits = 2
			assert_equal(2, record.exits)
			record.next = 3
			assert_equal(3, record.next)
			record.key = 4
			assert_equal(4, record.key)
			record.fail = "fail"
			assert_equal("fail", record.fail)
			record.succ = "succ"
			assert_equal("succ", record.succ)
			record.ofail = "ofail"
			assert_equal("ofail", record.ofail)
			record.osucc = "osucc"
			assert_equal("osucc", record.osucc)
			record.owner = 5
			assert_equal(5, record.owner)
			record.pennies = 6
			assert_equal(6, record.pennies)
			record.flags = 7
			assert_equal(7, record.flags)
			record.password = "password"
			assert_equal("password", record.password)
			# None of the derived flag methods warrant testing (for now)
		end
    end
end

# PUT RECORD TEST!!!!

# REGRESSION?
## READ!!!!
#puts "Reading file..."
#db.read("minimal.db")
#puts "Read file... #{db.length} entries found"
#for i in 0..(db.length - 1)
#	puts "Record #{i}"
#	puts "-----------"
#	print(db.get(i))
#	puts
#end
