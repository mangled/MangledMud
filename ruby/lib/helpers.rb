require_relative 'constants'

# !!! This module should go away as we refactor !!!
module Helpers
  # Build an enumerator which loops from dbref, through its .next links
  def enum(dbref)
    Enumerator.new do |yielder|
      while (dbref != TinyMud::NOTHING)
        yielder.yield dbref
        dbref = @db[dbref].next
      end
    end
  end

  def typeof(item)
    (@db[item].flags & TinyMud::TYPE_MASK)
  end

  def getloc(thing)
    @db[thing].location
  end
end
