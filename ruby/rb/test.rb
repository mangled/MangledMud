require 'rubygems'
require 'test/unit'
require 'jam'
require 'mocha'

class TestJam < Test::Unit::TestCase
    def test_jam
        jam = Jam.new
        Jam.expects(:hello)
        jam.stub
    end
end

