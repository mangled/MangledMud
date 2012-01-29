#Port of Tinymud's db.c to Ruby.  See http://mangled.me/blog/coding/ruby-port-of-tinymud-wip/
#Author: Alexander Morrow
#Email:	 amo3@umbc.edu

require_relative '../test/include'
require 'pp'
module TinyMud

	#Db class is used to handle administrative database changes.  Holds records.
	class Db
		#Not happy with making record_array static, but was the only way I knew of
		#to have Minimal work correctly as a static function.
		#
		#Perhaps after converting this over, Minimal would be better as a
		#standard object function.
		
		
		#Static class function. Sets up a Minimal database by parsing
		#text from minimal.db to create rooms, etc. .
		def self.Minimal()
			parse_database("minimal.db")
		end
		
		#Helper function, parses a database from a file.
		def self.parse_database(location)
			@@record_array = Array.new()
			if(File.exist?(location))
				file = File.new(location, "r")
				string_array = file.readlines()
				
				#Each record should have 16 entries.  Total number of lines should
				#be (16 * n)+1 for end of file.
				if((string_array.length() - 1)%16 != 0)
					raise "Corrupted database."
				else			
					counter = 0;
					for i in (1..((string_array.length()-1)/16))
						#Record type and desc (not description) not in file.
						currentRecord = Record.new()
						offset = counter * 16
						currentRecord.name = string_array[offset+1].strip()
						currentRecord.description = string_array[offset+2].strip()
						currentRecord.location = Integer(string_array[offset+3].strip())
						currentRecord.contents = Integer(string_array[offset+4].strip())
						currentRecord.exits = Integer(string_array[offset+5].strip())
						currentRecord.next = Integer(string_array[offset+6].strip())
						currentRecord.key = Integer(string_array[offset+7].strip())
						currentRecord.fail = string_array[offset+8].strip()
						currentRecord.succ = string_array[offset+9].strip()
						currentRecord.ofail = string_array[offset+10].strip()
						currentRecord.osucc = string_array[offset+11].strip()
						currentRecord.owner = Integer(string_array[offset+12].strip())
						currentRecord.pennies = Integer(string_array[offset+13].strip())
						currentRecord.flags = Integer(string_array[offset+14].strip())
						currentRecord.password = string_array[offset+15].strip()
						counter += 1
						
						
						#Chek to see if any of the messages are empty.

						if currentRecord.name == ""
							currentRecord.name = nil
						end
						if currentRecord.description == ""
							currentRecord.description = nil
						end
						if currentRecord.fail == ""
							currentRecord.fail = nil
						end
						if currentRecord.succ == ""
							currentRecord.succ = nil
						end
						if currentRecord.ofail == ""
							currentRecord.ofail = nil
						end
						if currentRecord.osucc == ""
							currentRecord.osucc = nil
						end
						if currentRecord.password == ""
							currentRecord.password = nil
						end
				

						@@record_array << currentRecord
					end
				end
				file.close
			else
				raise "File not found."
			end
		end
		
		#Creates a new, empty database. Starts empty.
		def initialize()
			@@record_array = Array.new()
		end
		
		
		#Adds a new blank record to the end of the database.
		def add_new_record()
			@@record_array << Record.new()
			
			#pp @@record_array
			#Some sort of issue here... returning -1 all the time?
			#Or issue may be in put function recieving a fixnum.
			index = @@record_array.length() -1
			return index
		end
		
		#Adds a record to the database at the specified index.
		#	Putting in  an empty database					->		Error.
		#	Putting at a location that doesn't exist		->		Error.
		#	Putting an object that is not a record			->		Error.
		def put(index,record)
			if(record.class() != Record)
				#raise RuntimeError
				raise "argument is not a record"
			elsif(@@record_array.length() == 0)
				#raise RuntimeError
				raise "record array empty"
			elsif(@@record_array.length() < index || index < 0)
				#raise RuntimeError
				raise "record array length is less than index or index is less than 0"
			else
				@@record_array[index] = record
			end
		end
		
		#Returns a handle to Record object at specified index.	
		#	Getting from an empty database					->		Error.
		#	Getting from a location that doesn't exist		->		Error.
		def get(index)
			if(@@record_array.length() == 0)
				#raise RuntimeError
				raise "record array length is 0"
			elsif(@@record_array.length() <= index || index < 0)
				#raise RuntimeError
				raise "trying to get #{index}, but array length is #{@@record_array.length()}"
			else
				return @@record_array[index]
			end
		end
		
		#length returns the number of elements in the database.
		def length()
			return @@record_array.length()
			
			
		end
		
		#Helper function, parses a database from a file.
		def read(location)
			Db.parse_database(location)
		end
		
		#Writes current database to location
		def write(location)
			file = File.new(location, "w")
			
			for i in (0..record_array.length())
			end
			
			
		end
		
		#free clears the database and does administrative work
		def free()
			@@record_array = Array.new()
			
		end
		
	end
	
	#Record class is used to store individual information about rooms, things, exits, playes, notypes, and unknowns.
	class Record
		
		#Getteer and Setter methods for the following variables.
		attr_accessor :name, :description, :location, :contents, :exits, :next, :key, :fail, :succ, :ofail, :osucc, :owner, :pennies, :flags, :password 
		#:type, :desc, :flags default values?
		#initialize record object to new values.
		def initialize()
			@name			=		nil
			@description	=		nil
			@location		=		NOTHING
			@contents		=		NOTHING
			@exits			=		NOTHING
			@next			=		NOTHING
			@key			=		NOTHING
			@fail			=		nil
			@succ			=		nil
			@ofail			=		nil
			@osucc			=		nil
			@owner			=		NOTHING
			@pennies		=		0
			#What should type, desc, and flags initialize to?
			@type			=		0
			@desc			=		NOTHING
			@flags			=		NOTHING
			@password		=		nil
		
		end
		
		#Type is defined by the flags, and uses defines.rb
		def type()
			type_after_mask = flags & TYPE_MASK
			
			#Switch
			case type_after_mask
				when TYPE_ROOM
					return "TYPE_ROOM"
				when TYPE_THING
					return "TYPE_THING"
				when TYPE_EXIT
					return "TYPE_EXIT"
				when TYPE_PLAYER
					return "TYPE_PLAYER"
				when NOTYPE
					return "NOTYPE"
				else
					return "UNKNOWN"
				end
		end
		
		def desc()
			if (flags & ANTILOCK)!= 0
				return "ANTILOCK"
			elsif (flags & WIZARD) != 0
				return "WIZARD"
			elsif (flags & LINK_OK) != 0
				return "LINK_OK"
			elsif (flags & DARK) != 0
				return "DARK"
			elsif (flags & TEMPLE) != 0
				return "TEMPLE"
			elsif (flags & STICKY) != 0
				return "STICKY"
			else
				return nil
			end
		
		end
		
	end
	
end