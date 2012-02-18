require_relative 'constants'

module TinyMud
  # The main entity used to store objects in the game
  class Record
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

    #Type is defined by the flags, and uses constants.rb
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
