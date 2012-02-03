require_relative '../test/include'
require_relative '../test/defines.rb'
require_relative './helpers.rb'

module TinyMud
  class Set
    include Helpers

    def initialize(db)
      @db = db
    end

    def do_name(player, name, newname)
    end
    
    def do_describe(player, name, description)
    end
    
    def do_fail(player, name, message)
    end
    
    def do_success(player, name, message)
    end
    
    def do_osuccess(player, name, message)
    end
    
    def do_ofail(player, name, message)
    end
    
    def do_lock(player, name, keyname)
    end
    
    def do_unlock(player, name)
    end
    
    def do_unlink(player, name)
    end
    
    def do_chown(player, name, newobj)
    end
    
    def do_set(player, name, flag)
    end
  end
end
