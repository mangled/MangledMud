require_relative 'constants'
require_relative 'record'

# The main module for MangledMUD related code
# @version 1.0
module MangledMud

  # Db class is responsible for database management holding player, room, exit, and object records.
  class Db
  
    # Static class function. Sets up a Minimal database by parsing
    # text from minimal.db to create rooms, etc.
    # @return [MangledMud::Db] Copy of the Minimal database loaded from file.
    def self.Minimal()
      db = Db.new()
      db.load("minimal.db")
      db
    end

    # Creates an empty database, replacing anything that existed in the database before.
    def initialize()
      @record_array = Array.new()
    end

    # Loads a database from the given filename (replaces current contents).  
    # @param [String] the name of the file to load.
    def load(filename)
      @record_array = Array.new()
      raise "File not found at #{filename}" unless File.exist?(filename)

      record_size = 16
      end_of_records = Regexp.escape("***END OF DUMP***")
      File.open(filename) do |file|
        while true
          record_start = file.readline.strip()
          break if record_start.match(end_of_records)
          raise "expected a dbref found this \"#{record_start}\" instead" unless record_start =~ /#\d+/

          lines = 1.upto(record_size - 1).collect {|i| file.readline().strip() }
          r = Record.new()
          r.name = nullify(lines.shift)
          r.description = nullify(lines.shift)
          r.location = lines.shift.to_i
          r.contents = lines.shift.to_i
          r.exits = lines.shift.to_i
          r.next = lines.shift.to_i
          r.key = lines.shift.to_i
          r.fail = nullify(lines.shift)
          r.succ = nullify(lines.shift)
          r.ofail =nullify(lines.shift)
          r.osucc = nullify(lines.shift)
          r.owner = lines.shift.to_i
          r.pennies = lines.shift.to_i
          r.flags = lines.shift.to_i
          r.password = nullify(lines.shift)

          @record_array << r
        end
      end
    end

    # Adds a new blank record to the end of the database.
    # @return [Number] the index of the newly created record.
    def add_new_record()
      @record_array << Record.new()
      index = @record_array.length() -1
      return index
    end

    # Sets the database record as specified index to the record provided.
    # @param [Number] the index to replace.
    # @param [MangledMUD::Record] the record to add to the database.
    def []=(index, record)
      put(index, record)
    end

    # Accesses the database at a specified index and returns the record stored
    # at that location.  Raises exception if index is invalid.
    # @param [Number] the index to access.
    # @return [MangledMud::Record] Record at index given.
    def [](index)
      return get(index)
    end

    # length provides size of database.
    # @return [Number] the total number of elements in the database.
    def length()
      return @record_array.length()
    end

    # Converts a string into a number for use accessing the db.
    # @param [String] the string to parse.
    # @return [Number] the integer representation of the provided string, else NOTHING if invalid.
    def parse_dbref(s)
      if s
        x = s.to_i
        if (x > 0)
          return x
        elsif (x == 0)
          s = s.lstrip()
          return 0 if (s and s.start_with?('0'))
        end
      end
      # else x < 0 or s != 0
      return NOTHING
    end

    # Writes current database to location
    def write(location)
      File.open(location, "w") do |file|
        @record_array.each_with_index do |r, i|
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

    #Free clears the database.
    def free()
      @record_array.clear() if @record_array
    end

    private

    def nullify(s)
      return s == "" ? nil : s
    end

    # Accesses the database at a specified index and returns the record stored
    # at that location.  Raises exception if index is invalid.
    # @param [Number] the index to access.
    # @return [MangledMud::Record] Record at index given.
    def get(index)
      r = @record_array[index]
      raise "invalid index #{index}" if r.nil?
      return r
    end

    # Sets the database record as specified index to the record provided.
    # @param [Number] the index to replace.
    # @param [MangledMUD::Record] the record to add to the database.
    def put(index, record)
      raise "invalid index #{index}" unless (0...@record_array.length()).include?(index)
      @record_array[index] = record
    end
  end
end
