require 'stringio'
require_relative '../lib/db'

if __FILE__ == $0
    db = MangledMud::Db.new()
    db.load(StringIO.new(ARGF.read))

    exits = []
    rooms = []
    (0...db.length).each do |index|
      record = db[index]
      if (record.flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_EXIT
        exits << index
      elsif (record.flags & MangledMud::TYPE_MASK) == MangledMud::TYPE_ROOM
        rooms << index
      end
    end

    # Check I have sensible looking exits - todo, check destinations make sense
    room_exits = {}
    exits.each do |exit_index|
      room_index = rooms.find do |i|
        r = db[i]
        e = r.exits
        while (e != MangledMud::NOTHING)
          break if e == exit_index
          e = db[e].next
        end
        e == exit_index
      end
      if room_index
        if db[exit_index].location == room_index
          #puts "#{db[exit_index].name} is in \"#{db[room_index].name}\""
          puts "EXIT leads back to container w/o a lock on player lock - did you mean this?\n\t#{db[exit_index].name}(##{db[exit_index].key}) at #{db[room_index].name}" if db[exit_index].key != 179
        end
        room_exits[exit_index] = room_index
      else
        puts "#{db[exit_index].name} is in NOTHING!"
        exit(-1)
      end
    end

    # Check all exits are locked to the wizard - stops unlinked being tampered with
    exits.each do |exit_index|
      e = db[exit_index]
      if e.owner != 1
        puts "#{e.name} owner of #{e.owner} is not the wizard"
        exit(-1)
      end
    end

    # Link all bogus exits and ensure they are locked to the lock player
    exits.each do |exit_index|
      e = db[exit_index]
      if e.location == -1
        room_index = room_exits[exit_index]
        puts "#{e.name} is an unlinked bogus exit in \"#{db[room_index].name}\""
        e.location = room_index # the exit is now linked so it can't be re-purposed
        e.key = "179" # have to be the player lock
        #@link art=here --> the exit is now linked so it can't be re-purposed
        #@lock art=#179 --> have to be the player lock
      end
    end

    # save out...
    #db.save("mod.db")
end

#puts "Name: #{record.name}"
#puts "Destination: #{record.location}"
