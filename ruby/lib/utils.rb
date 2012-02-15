require_relative '../test/include'
require_relative '../test/defines.rb'
require_relative './helpers.rb'

module TinyMud

  class Utils
    include Helpers

    # When we rubify, we should pass the db into each method, this can
    # be a set of static helper functions.
    def initialize(db)
      @db = db
    end

    def remove_first(first, what)
      return @db.get(first).next if (first == what)
      before_what = enum(first).find{|item| @db.get(item).next == what }
      @db.get(before_what).next = @db.get(what).next if before_what
      first
    end

    def member(thing, list)
      enum(list).find{|item| item == thing } ? true : false
    end

    def reverse(list)
      newlist = NOTHING
      while(list != NOTHING)
        rest = @db.get(list).next
        @db.get(list).next = newlist
        newlist = list
        list = rest
      end
      return newlist
    end

    def getname(loc)
      case loc
        when NOTHING then "***NOTHING***"
        when HOME then "***HOME***"
        else @db.get(loc).name
      end
    end
  end
end
