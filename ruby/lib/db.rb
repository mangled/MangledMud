#Port of Tinymud's db.c to Ruby.  See http://mangled.me/blog/coding/ruby-port-of-tinymud-wip/
#Author: Alexander Morrow
#Email:	 amo3@umbc.edu

require_relative 'include'
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
			if(File.exist?(location))
				file = File.new(location, "r")
				string_array = file.readlines()
				
				#Each record should have 16 entries.  Total number of lines should
				#be (16 * n)+1 for end of file.
				if((string_array.length() - 1)%16 != 0)
					raise "Corrupted database."
				else			
					counter = 0;
					for i in (0..((string_array.length()-1)/16))
						#Record type and desc (not description) not in file.
						currentRecord = Record.new()
						offset = counter * 16
						currentRecord.name = string_array[offset+1]
						currentRecord.description = string_array[offset+2]
						currentRecord.location = string_array[offset+3]
						currentRecord.contents = string_array[offset+4]
						currentRecord.exits = string_array[offset+5]
						currentRecord.next = string_array[offset+6]
						currentRecord.key = string_array[offset+7]
						currentRecord.fail_message = string_array[offset+8]
						currentRecord.succ_message = string_array[offset+9]
						currentRecord.ofail = string_array[offset+10]
						currentRecord.osucc = string_array[offset+11]
						currentRecord.owner = string_array[offset+12]
						currentRecord.pennies = string_array[offset+13]
						currentRecord.flags = string_array[offset+14]
						currentRecord.password = string_array[offset+15]
						counter += 1
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
		end
		
		#free clears the database and does administrative work
		def free()
			@@record_array = Array.new()
			
		end
		
	end
	
	#Record class is used to store individual information about rooms, things, exits, playes, notypes, and unknowns.
	class Record
		
		#Getteer and Setter methods for the following variables.
		attr_accessor :name, :description, :location, :contents, :exits, :next, :key, :fail, :succ, :ofail, :osucc, :fail_message, :succ_message, :owner, :pennies, :type, :desc, :flags, :password 
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
			@fail_message	=		nil
			@succ_message	=		nil
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
		
	end
		
		
	
	
end