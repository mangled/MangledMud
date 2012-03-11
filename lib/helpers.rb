require_relative 'constants'

module Helpers

  # Build an enumerator which loops from dbref, through its .next links
  def enum(dbref)
    Enumerator.new do |yielder|
      while (dbref != MangledMud::NOTHING)
        yielder.yield dbref
        dbref = @db[dbref].next
      end
    end
  end

  def is_player(item)
    ((@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_PLAYER)
  end

  def is_thing(item)
    ((@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_THING)
  end

  def is_temple(item)
    ((@db[item].flags & MangledMud::TEMPLE) != 0)
  end

  def is_sticky(item)
    ((@db[item].flags & MangledMud::STICKY) != 0)
  end

  def is_link_ok(item)
    ((@db[item].flags & MangledMud::LINK_OK) != 0)
  end

  def is_antilock(item)
    ((@db[item].flags & MangledMud::ANTILOCK) != 0)
  end

  def typeof(item)
    (@db[item].flags & MangledMud::TYPE_MASK)
  end

  def room?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_ROOM
  end

  def player?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_PLAYER
  end

  def thing?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_THING
  end

  def exit?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_EXIT
  end

  def is_wizard(item)
    ((@db[item].flags & MangledMud::WIZARD) != 0)
  end
  
  def is_builder(item)
    ((@db[item].flags & (MangledMud::WIZARD | MangledMud::BUILDER)) != 0)
  end

  def is_dark(item)
    ((@db[item].flags & MangledMud::DARK) != 0)
  end

  def getloc(thing)
    @db[thing].location
  end
end
