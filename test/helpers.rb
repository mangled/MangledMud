# Test helpers
require_relative 'include'

module TestHelpers
    # Used all over the place: Simplify setting a records content - Note, assumes
    # @db instance variable
    def record(i)
        record = @db[i]

        args = {}
        args[:name] = record.name
        args[:description] = record.description
        args[:location] = record.location
        args[:contents] = record.contents
        args[:exits] = record.exits
        args[:next] = record.next
        args[:key] = record.key
        args[:fail] = record.fail
        args[:succ] = record.succ
        args[:ofail] = record.ofail
        args[:osucc] = record.osucc
        args[:owner] = record.owner
        args[:pennies] = record.pennies
        args[:flags] = record.flags
        args[:password] = record.password

        yield args

        args.each do |key, value|
            case key
            when :name
                record.name = value
            when :description
                record.description = value
            when :location
                record.location = value
            when :contents
                record.contents = value
            when :exits
                record.exits = value
            when :next
                record.next = value
            when :key
                record.key = value
            when :fail
                record.fail = value
            when :succ
                record.succ = value
            when :ofail
                record.ofail = value
            when :osucc
                record.osucc = value
            when :owner
                record.owner = value
            when :pennies
                record.pennies = value
            when :flags
                record.flags = value
            when :password
                record.password = value
            else
                raise("Record - unknown key #{key} with #{value}")
            end
        end
        @db[i] = record
    end
end
