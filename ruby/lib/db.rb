require_relative '../test/include'

module TinyMud

    class Db
		include Helpers
        # Static class function. Sets up a Minimal database by parsing
        # text from minimal.db to create rooms, etc. .
        def self.Minimal()
          parse_database("minimal.db")
        end
        
        # Helper function, parses a database from a file.
        def self.parse_database(location)
          @@record_array = Array.new()
          raise "File not found at #{location}" unless File.exist?(location)

          record_size = 16
          end_of_records = Regexp.escape("***END OF DUMP***")
          File.open(location) do |file|
            while true
              record_start = file.readline.strip()
              break if record_start.match(end_of_records)
              raise "expected a dbref found this \"#{record_start}\" instead" unless record_start =~ /#\d+/

              lines = 1.upto(record_size - 1).collect {|i| file.readline().strip() }
              r = Record.new()
              r.name = self.nullify(lines.shift)
              r.description = self.nullify(lines.shift)
              r.location = lines.shift.to_i
              r.contents = lines.shift.to_i
              r.exits = lines.shift.to_i
              r.next = lines.shift.to_i
              r.key = lines.shift.to_i
              r.fail = self.nullify(lines.shift)
              r.succ = self.nullify(lines.shift)
              r.ofail =self.nullify(lines.shift)
              r.osucc = self.nullify(lines.shift)
              r.owner = lines.shift.to_i
              r.pennies = lines.shift.to_i
              r.flags = lines.shift.to_i
              r.password = self.nullify(lines.shift)

              @@record_array << r
            end
          end
        end

        #Creates a new, empty database. Starts empty.
        def initialize()
          @@record_array = Array.new()
        end

        #Adds a new blank record to the end of the database.
        def add_new_record()
          @@record_array << Record.new()
          index = @@record_array.length() -1
          return index
        end

        def []=(index, record)
          put(index, record)
        end

        def [](index)
          return get(index)
        end

        #length returns the number of elements in the database.
        def length()
          return @@record_array.length()
        end
        
        #Helper function, parses a database from a file.
        def read(location)
          Db.parse_database(location)
        end

        def self.parse_dbref(s)
            x = s.to_i
            if (x > 0)
                return x
            elsif (x == 0)
                s = s.lstrip() unless s.nil?
                return 0 if (s and s.start_with?('0'))
            end
            # else x < 0 or s != 0
            return NOTHING
        end

        #Writes current database to location
        def self.write(location)
            File.open(location, "w") do |file|
              @@record_array.each_with_index do |r, i|
                  file.puts("##{i}\n")
                  file.puts(r.name)
                  file.puts(r.description)
                  file.puts(r.location)
                  file.puts(r.contents)
                  file.puts(r.exits)
                  file.puts(r.next)
                  file.puts(r.key)
                  file.puts(r.fail)
                  file.puts(r.succ)
                  file.puts(r.ofail)
                  file.puts(r.osucc)
                  file.puts(r.owner)
                  file.puts(r.pennies)
                  file.puts(r.flags)
                  file.puts(r.password)
              end
              file.puts("***END OF DUMP***")
            end
        end

        #free clears the database
        def free()
            @@record_array.clear() if @@record_array
        end

    private

        def self.nullify(s)
          return s == "" ? nil : s
        end

        def get(index)
            r = @@record_array[index]
            raise "invalid index #{index}" if r.nil?
            return r
        end

        def put(index, record)
            raise "invalid index #{index}" unless (0...@@record_array.length()).include?(index)
            @@record_array[index] = record
        end
    end

    #Record class is used to store individual information about rooms, things, exits, playes, notypes, and unknowns.
    class Record
	include Helpers
      attr_accessor :name, :description, :location, :contents, :exits, :next, :key, :fail, :succ, :ofail, :osucc, :owner, :pennies, :flags, :password 

      def initialize()
          @name           =       nil
          @description    =       nil
          @location       =       NOTHING
          @contents       =       NOTHING
          @exits          =       NOTHING
          @next           =       NOTHING
          @key            =       NOTHING
          @fail           =       nil
          @succ           =       nil
          @ofail          =       nil
          @osucc          =       nil
          @owner          =       NOTHING
          @pennies        =       0
          @type           =       0
          @desc           =       nil
          @flags          =       0
          @password       =       nil
      end

      #Type is defined by the flags, and uses defines.rb
      def type()
        case flags & TYPE_MASK
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
        if (flags & ANTILOCK) != 0
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
