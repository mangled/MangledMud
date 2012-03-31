require_relative 'constants'
require_relative 'record'

# The main module for MangledMUD related code
# @version 1.0
module MangledMud

  # Db class is responsible for database management holding player, room, exit, and object records.
  # @version 1.0
  class Db

    # Creates an empty database, replacing anything that existed in the database before.
    def initialize()
      @record_array = Array.new()
    end

    # Loads a database from the given filename (replaces current contents).
    #
    # @param [Object] source the input stream to read from (if supports readline()) or filename (supports to_str() - read from a file on disk)
    # @return [Db] self
    def load(source)
      if source.respond_to? :readline
        restore(source)
      elsif source.respond_to? :to_str
        raise "File not found at #{source}" unless File.exist?(source)
        File.open(source) {|file| restore(file) }
      else
        raise "#{arg.class} is not a valid input stream"
      end
      self
    end

    # Saves the current database to a given stream
    #
    # @param [Object] destination the output stream to write to (if supports puts()) or filename (supports to_str() - write to a file on disk)
    def save(destination)
      if destination.respond_to? :puts
        serialize(destination)
      elsif destination.respond_to? :to_str
        File.open(destination, "wb") {|file| serialize(file) }
      else
        raise "#{arg.class} is not a valid output stream"
      end
    end

    # Adds a new blank record to the end of the database.
    #
    # @return [Number] the index of the newly created record.
    def add_new_record()
      @record_array << Record.new()
      index = @record_array.length() -1
      return index
    end

    # Sets the database record as specified index to the record provided.
    #
    # @param [Number] index the index to replace.
    # @param [Record] record the record to add to the database.
    def []=(index, record)
      put(index, record)
    end

    # Accesses the database at a specified index and returns the record stored
    # at that location.  Raises exception if index is invalid.
    #
    # @param [Number] index the index to access.
    # @return [Record] record at index given.
    def [](index)
      return get(index)
    end

    # length provides size of database.
    #
    # @return [Number] the total number of elements in the database.
    def length()
      return @record_array.length()
    end

    # Converts a string into a number for use accessing the db.
    #
    # @param [String] s the string to parse.
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

    # Clears (empties) the database.
    def free()
      @record_array.clear() if @record_array
    end

    private

    # Writes the database to the given stream
    def serialize(stream)
      @record_array.each_with_index {|r, i| r.write(i, stream) }
      stream.puts("***END OF DUMP***")
    end

    # Reads the database from the given stream
    def restore(stream)
      @record_array = Array.new()
      end_of_records = Regexp.escape("***END OF DUMP***")
      while true
        record_start = stream.readline.strip()
        break if record_start.match(end_of_records)
        raise "expected a dbref found this \"#{record_start}\" instead" unless record_start =~ /#\d+/
        @record_array << Record.restore(stream)
      end
    end

    # Accesses the database at a specified index and returns the record stored
    # at that location.  Raises exception if index is invalid.
    def get(index)
      r = @record_array[index]
      raise "invalid index #{index}" if r.nil?
      return r
    end

    # Sets the database record as specified index to the record provided.
    def put(index, record)
      raise "invalid index #{index}" unless (0...@record_array.length()).include?(index)
      @record_array[index] = record
    end
  end
end
