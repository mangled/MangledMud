require_relative 'constants'

module MangledMud

  # The record class holds all the fields used to define particular features of a player, object, room, or exit.
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
    # @return [Number] Flags indicating type and other meta details
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
  end
end
