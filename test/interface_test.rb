# Drive a running instance of TinyMUD through a scripted set of commands
# This is used to test the networking
#
# It could be extended to perform a wider set of tests, but the regression
# commands already do this and they don't require networking, which makes
# them cleaner.
require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'diff/lcs'
require 'diff/lcs/array'
require 'mocha'
require 'net/telnet'
require 'thwait'
require_relative 'player'

module TinyMudTest

    class Test::Unit::TestCase

      def setup
        @test_name = self.instance_variable_get(:@__name__)
        @regression_tmp_filename = File.join(File.dirname(__FILE__), "#{@test_name}.tmp")
        @regression_pass_filename = File.join(File.dirname(__FILE__), "#{@test_name}.pass")
        File.delete @regression_tmp_filename if File.exists? @regression_tmp_filename
        @regression = File.open(@regression_tmp_filename, "wb")
      end

      def teardown
        @regression.close()
        if !File.exists? @regression_pass_filename
          raise "Missing pass file #{@regression_pass_filename} for test #{@test_name}"
        else
          # Faf, due to windows/linux diff and eol's
          pass = open(@regression_pass_filename) {|f| f.readlines }
          curr = open(@regression_tmp_filename) {|f| f.readlines }
          diffs = Diff::LCS.diff(curr, pass)
          if diffs.length > 0
              diffs.each do |diff|
                  diff.each do |change|
                      puts "#{change.position} #{change.action} #{change.element}"
                  end
              end
              assert_equal(0, diffs.length, "regression failed for #{@regression_pass_filename}")
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
        # As it says!
        check_network_failure_handling()

        # Connect the wizard
        wizard = TinyMudTest::Player.new(@regression, "wizard", "potrzebie")
        
        # Connect and create a new player bob
        bob = TinyMudTest::Player.new(@regression, "bob", "1234", true)
        
        # Try to connect another player bob...
        TinyMudTest::Player.new(@regression, "bob", "5678", true, true)
        
        # Who
        wizard.cmd("WHO")
        
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

      # An attempt at triggering some common network failures - To ensure the code is robust
      # at a basic level. See player.rb for the constants
      def check_network_failure_handling
        # Open a connection then close
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        s.close

        # Open a connection, send something then close
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        s.puts "boing"
        s.close

        # Open a read, then close
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        @regression.puts(s.gets)
        s.close

        # Open, read, create, close
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        @regression.puts(s.gets)
        s.puts "create foo 1234"
        s.close

        # Open, send multiple lines
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        @regression.puts(s.gets)
        s.puts ["create foo 1234", "look", "@dig", "inventory", "look"].join("\n")
        @regression.puts(s.gets)
        sleep(0.25) # Ensure it gets time to consume
        s.close

        # as above, but fragment line
        s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
        @regression.puts(s.gets)
        ["cr", "eate", " foo", " 12", "34\n"].each {|b| s.puts b }
        @regression.puts(s.gets)
        sleep(0.25)  # Ensure it gets time to consume
        s.close
      end

    end
end

