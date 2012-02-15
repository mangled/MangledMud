# Drive a running instance of TinyMUD through a scripted set of commands
# This is used to test the networking implementation in interface.rb
# it could be extended to perform a wider set of tests, but the regression
# commands already do this and they don't require networking, which makes
# them cleaner.
require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require 'net/telnet'
require 'thwait'
require_relative 'player.rb'

module TinyMud

    class Test::Unit::TestCase

      def setup
        @test_name = self.instance_variable_get(:@__name__)
        @regression_tmp_filename = File.join(File.dirname(__FILE__), "#{@test_name}.tmp")
        @regression_pass_filename = File.join(File.dirname(__FILE__), "#{@test_name}.pass")
        File.delete @regression_tmp_filename if File.exists? @regression_tmp_filename
        @regression = File.open(@regression_tmp_filename, "w")
      end

      def teardown
        @regression.close()
        if !File.exists? @regression_pass_filename
            raise "Missing pass file #{@regression_pass_filename} for test #{@test_name}"
        else
            diff = `diff #{@regression_pass_filename} #{@regression_tmp_filename}`
            unless $? == 0
                puts diff
                assert(false, "regression failed for test #{@test_name}")
            else
                File.delete(@regression_tmp_filename)
            end
        end
      end

      # This test assumes that a tinymud server has started with a fresh minimal database
      # I tried starting the process and killing it per test but it bails out
      # and doesn't clean up the ports properly, so things go wrong on the second
      # run.
      def test_interface
        # Connect the wizard
        wizard = TinyMudTest::Player.new(@regression, "wizard", "potrzebie")

        # Connect and create a new player bob
        bob = TinyMudTest::Player.new(@regression, "bob", "1234", true)

        # Try to connect another player bob...
        another_bob = TinyMudTest::Player.new(@regression, "bob", "5678", true, true)

        # Who
        wizard.who()

        # non wizard dump and shutdown
        bob.cmd("@dump")
        bob.shutdown()

        # wizard dump
        wizard.cmd("@dump")

        # quit
        bob.quit
        wizard.quit

        # Invalid password
        bob = TinyMudTest::Player.new(@regression, "bob", "1111", false, true)

        # Now connect and create a number of players (on threads)
        # each player will create a number of items in order
        # then list their inventory - Which should contain
        # The expected content, in order. This tests locking and
        # multiple server write operations. Only the create is threaded
        # and I don't log the create responses - This is to allow for the
        # fact the threads can execute in any order and so I don't want
        # the regression tests to always fail as a result. The main
        # "assertion" is that their inventories have the correct content
        wizard = TinyMudTest::Player.new(@regression, "wizard", "potrzebie")
        player_connections = {}
        1.upto(5) do |i|
          player_connections[i] = TinyMudTest::Player.new(@regression, "#{i}", "password", true)
          wizard.cmd("give #{i}=100")
        end
        players = ThreadsWait.new
        1.upto(5) do |i|
            thread = Thread.new { 1.upto(10) {|j| player_connections[i].cmd("@create #{i}#{j}", false) } }
            players.join_nowait(thread)
        end
        players.all_waits
        1.upto(5) do |i|
          # The number can change based on thread order, hence we ignore the object id's in the inventory
          player_connections[i].cmd("inventory", true, true)
          player_connections[i].cmd("say #{i}")
          player_connections[i].quit()
        end
        wizard.quit

        # Do this last...
        # Connect the wizard again
        wizard = TinyMudTest::Player.new(@regression, "wizard", "potrzebie")
        wizard.shutdown()
      end

    end
end

