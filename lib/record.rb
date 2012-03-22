require_relative 'constants'

module MangledMud

  # The record class holds all the fields used to define particular features of a player, object, room, or exit.
  class Record
    attr_accessor :name         # The name of the object
    attr_accessor :description  # A description of the object
    attr_accessor :location     # The objects container
    attr_accessor :contents     # For exits, pointer to destination, else a room or players contents
    attr_accessor :exits        # Pointer to first exit for rooms, pointer to home for things and players
    attr_accessor :next         # Next in the contents/exits chain
    attr_accessor :key          # If this isn't empty then you must have this to do the operation
    attr_accessor :fail         # What you see if the operation fails
    attr_accessor :succ         # What you see if the operation succeeds
    attr_accessor :ofail        # What others see if the operation fails
    attr_accessor :osucc        # What others see if the operation succeeds
    attr_accessor :owner        # Who controls this object
    attr_accessor :pennies      # Number of pennies this object contains
    attr_accessor :flags        # Flags indicating type and other meta details
    attr_accessor :password     # Password for players

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
