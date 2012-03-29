require_relative 'helpers'

module MangledMud

  # Various utility functions
  #
  # @version 1.0
  class Utils
    include Helpers

    # @param [Db] db the current database instance
    def initialize(db)
      @db = db
    end

    # Remove an item from a database record's next chain
    #
    # @note This method is confusing :-)
    # @param [Number] first the database record number for the record object starting the chain
    # @param [Number] what the database record number for the record object to remove from the next chain of first
    # @return [Number] The database record number of the next item or first if the item was removed
    def remove_first(first, what)
      return @db[first].next if (first == what)
      before_what = enum(first).find{|item| @db[item].next == what }
      @db[before_what].next = @db[what].next if before_what
      first
    end

    # Is something held within a database record's next chain?
    #
    # @param [Number] thing the database record number for the thing to be found
    # @param [Number] list the database record number for the record object starting the chain
    # @return [Boolean] true if thing is in the list
    def member(thing, list)
      enum(list).find{|item| item == thing } ? true : false
    end

    # Reverse the ordering of a database record's next chain
    #
    # @param [Number] list the database record number for the record object starting the chain
    # @return [Number] the head of the reversed chain
    def reverse(list)
      newlist = NOTHING
      while(list != NOTHING)
        rest = @db[list].next
        @db[list].next = newlist
        newlist = list
        list = rest
      end
      return newlist
    end

    # Get the location name for a thing
    #
    # @param [Number] loc the database record identifier
    # @return [String] the location's name
    def getname(loc)
      case loc
      when NOTHING then Phrasebook.lookup('loc-nothing')
      when HOME then Phrasebook.lookup('loc-home')
      else @db[loc].name
      end
    end
  end
end
