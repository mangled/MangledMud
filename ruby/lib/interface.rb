require_relative '../test/include'
require_relative './helpers.rb'

module TinyMud
  class Interface
    include Helpers

    # Interface will eventually hold all the networking code...
    def self.do_notify()
    end

  end
end
