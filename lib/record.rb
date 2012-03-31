require_relative 'constants'

module MangledMud

  # The record class holds all the fields used to define particular features of a player, object, room, or exit.
  #
  # @version 1.0
  # @see Db
  class Record
    # @return [String] The name of the object
    attr_accessor :name
    # @return [String] A description of the object
    attr_accessor :description
    # @return [Number] The objects container
    attr_accessor :location
    # @return [Number] For exits, pointer to destination, else a room or players contents
    attr_accessor :contents
    # @return [Number] Pointer to first exit for rooms, pointer to home for things and players
    attr_accessor :exits
    # @return [Number] Next in the contents/exits chain
    attr_accessor :next
    # @return [String] If this isn't empty then you must have this to do the operation
    attr_accessor :key
    # @return [Number] What you see if the operation fails
    attr_accessor :fail
    # @return [String] What you see if the operation succeeds
    attr_accessor :succ
    # @return [String] What others see if the operation fails
    attr_accessor :ofail
    # @return [String] What others see if the operation succeeds
    attr_accessor :osucc
    # @return [Number] Who controls this object
    attr_accessor :owner
    # @return [Number] Number of pennies this object contains
    attr_accessor :pennies
    # @return [Number] Flags indicating type and other meta details, see: {TYPE_ROOM}, {TYPE_THING}, {TYPE_EXIT}, {TYPE_PLAYER}, {NOTYPE}, {TYPE_MASK}, {ANTILOCK}, {WIZARD}, {LINK_OK}, {DARK}, {TEMPLE}, {STICKY}
    attr_accessor :flags
    # @return [String] Password for players
    attr_accessor :password

    # Initializes a blank record.  Default values vary by field.
    def initialize()
      @name        =  nil
      @description =  nil
      @fail        =  nil
      @succ        =  nil
      @ofail       =  nil
      @osucc       =  nil
      @desc        =  nil
      @password    =  nil
      @location    =  NOTHING
      @contents    =  NOTHING
      @exits       =  NOTHING
      @next        =  NOTHING
      @key         =  NOTHING
      @owner       =  NOTHING
      @pennies     =  0
      @type        =  0
      @flags       =  0
    end

    # Restores a new record object from the given source.
    #
    # @param [Object] source source to read from, must support readline() function
    # @return [Record] returns a new record
    def Record.restore(source)
      Record.new().read(source)
    end

    # Read contents from a stream
    #
    # @param [Object] source source to read from, must support readline() function
    # @param [Record] returns self
    def read(source)
      self.name        = read_string(source)
      self.description = read_string(source)
      self.location    = read_int(source)
      self.contents    = read_int(source)
      self.exits       = read_int(source)
      self.next        = read_int(source)
      self.key         = read_int(source)
      self.fail        = read_string(source)
      self.succ        = read_string(source)
      self.ofail       = read_string(source)
      self.osucc       = read_string(source)
      self.owner       = read_int(source)
      self.pennies     = read_int(source)
      self.flags       = read_int(source)
      self.password    = read_string(source)
      self
    end

    # Write content to a stream
    #
    # @param [Integer] index the record's identifier
    # @param [Object] destination the ouput stream, must support puts() function
    def write(index, destination)
      destination.puts("##{index}")
      destination.puts(name)
      destination.puts(description)
      destination.puts(location)
      destination.puts(contents)
      destination.puts(exits)
      destination.puts(self.next)
      destination.puts(key)
      destination.puts(fail)
      destination.puts(succ)
      destination.puts(ofail)
      destination.puts(osucc)
      destination.puts(owner)
      destination.puts(pennies)
      destination.puts(flags)
      destination.puts(password)
    end

    private

    # Helper, read a line from source and optionally set it to nil if its empty
    def read_string(source, empty_implies_nil = true)
      line = source.readline().strip()
      line = nullify(line) if empty_implies_nil
      line
    end

    # Helper, read a line from source and convert it to an integer
    def read_int(source)
      source.readline().strip().to_i
    end

    # If s is empty then return nil
    def nullify(s)
      return s == "" ? nil : s
    end
  end
end
