require_relative 'constants'

# A mix-in module to provide various common helper methods
# @note These would ideally be presented through a database adapter and so represent a legacy of the initial port
# @version 1.0
module Helpers

  # Enumerate the given database record number and it's chain of next items
  # @param [Number] dbref the starting database record number
  # @yield [Number] a database record number
  # @see MangledMud::Record#next
  def enum(dbref)
    Enumerator.new do |yielder|
      while (dbref != MangledMud::NOTHING)
        yielder.yield dbref
        dbref = @db[dbref].next
      end
    end
  end

  # Does the given database record represent a player?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a player, or not
  def is_player(item)
    ((@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_PLAYER)
  end

  # Does the given database record represent a thing?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a thing, or not
  def is_thing(item)
    ((@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_THING)
  end

  # Does the given database record represent a temple?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a temple, or not
  def is_temple(item)
    ((@db[item].flags & MangledMud::TEMPLE) != 0)
  end

  # Is the given database record sticky?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is sticky, or not
  def is_sticky(item)
    ((@db[item].flags & MangledMud::STICKY) != 0)
  end

  # Is the given database record linkable?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is linkable, or not
  def is_link_ok(item)
    ((@db[item].flags & MangledMud::LINK_OK) != 0)
  end

  # Does the given database record have anitlock set?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record has antilock set
  def is_antilock(item)
    ((@db[item].flags & MangledMud::ANTILOCK) != 0)
  end

  # Extract the type flags from a database record
  # @param [Number] item the database record number
  # @return [Number] the database records current type flags
  def typeof(item)
    (@db[item].flags & MangledMud::TYPE_MASK)
  end

  # Does the given database record represent a room?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a room, or not
  def room?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_ROOM
  end

  # Does the given database record represent a player?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a player, or not
  def player?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_PLAYER
  end

  # Does the given database record represent a thing?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a thing, or not
  def thing?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_THING
  end

  # Does the given database record represent an exit?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is an exit, or not
  def exit?(item)
    (@db[item].flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_EXIT
  end

  # Does the given database record represent a wizard?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a wizard, or not
  def is_wizard(item)
    ((@db[item].flags & MangledMud::WIZARD) != 0)
  end

  # Is the given database record dark?
  # @param [Number] item the database record number
  # @return [Boolean] indicates if the database record is a dark, or not
  def is_dark(item)
    ((@db[item].flags & MangledMud::DARK) != 0)
  end

  # Get the current location of a database record?
  # @param [Number] item the database record number
  # @return [Number] the database record identifier for the things location
  def getloc(thing)
    @db[thing].location
  end
end
