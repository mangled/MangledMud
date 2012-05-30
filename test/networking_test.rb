# Drive a running instance of MangledMUD through a scripted set of commands
# This is used to test the networking
#
# It could be extended to perform a wider set of tests, but the regression
# commands already do this and they don't require networking, which makes
# them cleaner.
#
# NOTE: One of the tests stresses the MUD looking for memory problems
# its worth using system monitor whilst this tests runs to see if the
# ruby process associated with the MUD starts using tons of memory
# It should stay fairly consistant.
#
require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'diff/lcs'
require 'diff/lcs/array'
require 'mocha'
require 'net/telnet'
require 'thwait'
require_relative 'player'

module MangledMudTest

  class Test::Unit::TestCase

    def setup
      @test_name = self.instance_variable_get(:@__name__)
      # Swap file name about
      @test_name = @test_name.gsub('test_', "") + "_test"
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

    # This test assumes that a tinymud server has started with a fresh *minimal* database
    # E.g. > ~/Source/tinymud $ ruby lib/mud.rb -d db/minimal.db -o dump
    def test_networking
      # As it says!
      check_network_failure_handling()

      # Connect the wizard
      wizard = MangledMudTest::Player.new(@regression, "wizard", "potrzebie")

      # Connect and create a new player bob
      bob = MangledMudTest::Player.new(@regression, "bob", "1234", true)

      # Try to connect another player bob...
      MangledMudTest::Player.new(@regression, "bob", "5678", true, true)

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
      bob = MangledMudTest::Player.new(@regression, "bob", "1111", false, true)

      # Now connect and create a number of players (on threads)
      # each player will create a number of items in order
      # then list their inventory - Which should contain
      # The expected content, in order. This tests locking and
      # multiple server write operations. Only the create is threaded
      # and I don't log the create responses - This is to allow for the
      # fact the threads can execute in any order and so I don't want
      # the regression tests to always fail as a result. The main
      # "assertion" is that their inventories have the correct content
      wizard = MangledMudTest::Player.new(@regression, "wizard", "potrzebie")
      player_connections = []
      1.upto(5) do |i|
        player_connections << MangledMudTest::Player.new(@regression, "#{i}", "password", true)
        wizard.cmd("give #{i}=100")
      end
      players = ThreadsWait.new
      player_connections.each_with_index do |connection, i|
        thread = Thread.new { 1.upto(10) {|j| connection.cmd("@create #{i}#{j}", false) } }
        players.join_nowait(thread)
      end
      players.all_waits
      player_connections.each_with_index do |connection, i|
        # The number can change based on thread order, hence we ignore the object id's in the inventory
        connection.cmd("inventory", true, true)
        connection.cmd("say #{i}")
        connection.quit()
      end
      wizard.quit

      # Before release we held a small party, the network code would through out all connections
      # every so often. This seemed to be caused by the drunk guy bot crashing (this behaviour has
      # been fixed) - This test tries to re-create the scenario. It re-uses some of the players above
      # and the wizard. The wizard performs some actions then closes the connection (not using QUIT)
      # this detected one error - sessions were remaining connected to players resulting in multiple
      # sessions handling a players input! One of which was associated with the network connection.
      # This caused memory usage to grow over time as the zombie sessions would acrue output!
      #
      # See note at top of file - consider monitoring with system monitor also
      #
      # First connect the players
      player_connections = []
      1.upto(5) do |i|
        player_connections << MangledMudTest::Player.new(@regression, "#{i}", "password", false, false, false)
      end

      # Loop around, performing actions then quitting without calling the mud "QUIT" command
      # This thrashes the MUD and should detect if anything is being held onto when connections
      # end in unexpected ways i.e. not through the "QUIT" command.
      1.upto(100) do |i|
        # Now the wizard
        wizard = MangledMudTest::Player.new(@regression, "wizard", "potrzebie", false, false, false)
        # Perform the same action a number of times - Not logging out these interactions
        # this test is about network failure, we want to get to the end of it without
        # a player connection freezing or the server refusing to accept more connections
        1.upto(50) {|j| wizard.cmd("look", false) }

        # Alternate between clean and un-clean exits
        (i % 2 == 0) ? wizard.quit(false) : wizard.close_connection()
      
        # Get the players to eat their buffers
        player_connections.each {|connection| connection.cmd("look", false) }
      end

      # Cleanup
      player_connections.each {|connection| connection.quit()}

      # Do this last...Test shutdown...
      #
      # Connect the wizard again
      wizard = MangledMudTest::Player.new(@regression, "wizard", "potrzebie")
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
      @regression.puts(s.gets.chomp)
      s.close

      # Open, read, create, close
      s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
      @regression.puts(s.gets.chomp)
      s.puts "create foo 1234"
      s.close

      # Open, send multiple lines
      s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
      @regression.puts(s.gets.chomp)
      s.puts ["create foo 1234", "look", "@dig", "inventory", "look"].join("\n")
      @regression.puts(s.gets.chomp)
      sleep(0.25) # Ensure it gets time to consume
      s.close

      # as above, but fragment line
      s = TCPSocket.new TINYMUD_HOST, TINYMUD_PORT
      @regression.puts(s.gets.chomp)
      ["cr", "eate", " foo", " 12", "34\n"].each {|b| s.puts b }
      @regression.puts(s.gets.chomp)
      sleep(0.25)  # Ensure it gets time to consume
      s.close
    end

  end
end

