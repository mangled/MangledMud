require_relative 'constants'

module TinyMud
  class Record
    attr_accessor :name, :description, :location, :contents, :exits, :next, :key, :fail, :succ, :ofail, :osucc, :owner, :pennies, :flags, :password 
    def initialize()
      @name        =  nil
      @description =  nil
      @location    =  NOTHING
      @contents    =  NOTHING
      @exits       =  NOTHING
      @next        =  NOTHING
      @key         =  NOTHING
      @fail        =  nil
      @succ        =  nil
      @ofail       =  nil
      @osucc       =  nil
      @owner       =  NOTHING
      @pennies     =  0
      @type        =  0
      @desc        =  nil
      @flags       =  0
      @password    =  nil
    end
  end
end
