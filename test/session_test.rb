require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'mocha'
require_relative 'include'
require_relative 'helpers'


module TinyMud
  # To simplify assertions we disregard some phrasebook lookups, so this test would break
  # in obvious ways, if the phrasebook strings were modified
  class TestSession < Test::Unit::TestCase
    include TestHelpers

    def setup
      @db = TinyMud::Db.new()
      @notifier = mock()
    end

    def teardown
      @db.free()
    end

    def test_do_create
      @db = Db.Minimal()
      game = mock()
      connected_players = mock()
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(session.player_id.nil?, "player id should be nil")
      assert(session.last_time.nil?, "last command time should be nil")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0], "output buffer should be greeting player")
    end

    def test_do_command_quit
      @db = Db.Minimal()
      game = mock()
      connected_players = mock()
      session = Session.new(@db, game, "foo", connected_players, @notifier)

      assert(session.do_command(Phrasebook.lookup('quit-command')), "should return true if quit signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Disconnected/, session.output_buffer[0], "output buffer should be waving player goodbye")
    end

    def test_do_command_who
      @db = Db.Minimal()
      wizard = 1
      bob = Player.new(@db, @notifier).create_player("bob", "pwd")

      game = mock()
      connected_players = mock()
      session = Session.new(@db, game, "foo", connected_players, @notifier)

      session1 = mock()
      session2 = mock()
      session1.expects(:player_id).returns(wizard)
      session1.expects(:last_time).returns(nil)
      session2.expects(:player_id).returns(bob)
      session2.expects(:last_time).twice().returns(Time.parse("2012-03-09"))
      connected_players.expects(:call).returns([session1, session2])

      assert(!session.do_command(Phrasebook.lookup('who-command')), "should return false if quit isn't signalled")
      assert_equal(3, session.output_buffer.length)
      assert_match(/#{Phrasebook.lookup('current-players')}/, session.output_buffer[0], "start list players")
      assert_match(/Wizard idle forever/, session.output_buffer[1], "wizard had an inactive time")
      assert_match(/bob idle \d+ seconds/, session.output_buffer[2], "bob had an active time")
    end

    def test_do_command_prefix_and_suffix
      @db = Db.Minimal()
      wizard = 1
      game = mock()
      connected_players = mock()

      session = Session.new(@db, game, "foo", connected_players, @notifier)

      assert(!session.do_command(Phrasebook.lookup('prefix-command') + " prefix"), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/#{Phrasebook.lookup('done-fix')}/, session.output_buffer[0])

      assert(!session.do_command(Phrasebook.lookup('suffix-command') + " suffix"), "should return false if quit isn't signalled")
      assert_match(/#{Phrasebook.lookup('done-fix')}/, session.output_buffer[0])

      # Who should be wrapped
      connected_players.expects(:call).returns([])
      assert(!session.do_command(Phrasebook.lookup('who-command')), "should return false if quit isn't signalled")
      assert_equal(3, session.output_buffer.length)
      assert_match(/prefix/, session.output_buffer[0])
      assert_match(/#{Phrasebook.lookup('current-players')}/, session.output_buffer[1])
      assert_match(/suffix/, session.output_buffer[2])

      # So should a connected player
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(wizard, "Limbo (#0)").in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, regexp_matches(/You are in a dense mist/)).in_sequence(notify)
      assert(!session.do_command('connect wizard potrzebie'), "should return false if quit isn't signalled")

      game.expects(:process_command).with(wizard, 'inventory').in_sequence(notify)
      assert(!session.do_command('inventory'), "should return false if quit isn't signalled")
      assert_equal(2, session.output_buffer.length)
      assert_match(/prefix/, session.output_buffer[0])
      assert_match(/suffix/, session.output_buffer[1])
    end

    def test_session_connect
      @db = Db.Minimal()
      wizard = 1
      game = mock()
      connected_players = mock()

      session = Session.new(@db, game, "foo", connected_players, @notifier)

      # connect should look
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(wizard, "Limbo (#0)").in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, regexp_matches(/You are in a dense mist/)).in_sequence(notify)
      assert(!session.do_command('connect wizard potrzebie'), "should return false if quit isn't signalled")
      assert_equal(0, session.output_buffer.length)

      # When we are connected, unknown commands should route through to the game
      game.expects(:process_command).with(wizard, 'hello')
      assert(!session.do_command('hello'), "should return false if quit isn't signalled")

      # connect again, same user - Surely this should be a failure i.e. the player is already connected on another
      # descriptor? I guess its weird but safe?
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      @notifier.expects(:do_notify).with(wizard, "Limbo (#0)").in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, regexp_matches(/You are in a dense mist/)).in_sequence(notify)
      assert(!session.do_command('connect wizard potrzebie'), "should return false if quit isn't signalled")
      assert_equal(0, session.output_buffer.length)

      # connect failure
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('connect foo bar'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/#{Phrasebook.lookup('connect-fail').chomp}/, session.output_buffer[0])

      # Missing user and password
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('connect'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0])

      # Missing password
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('connect bar'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0])
    end

    def test_session_create
      @db = Db.Minimal()
      wizard = 1
      game = mock()
      connected_players = mock()

      session = Session.new(@db, game, "foo", connected_players, @notifier)

      # Create should look
      notify = sequence('notify')
      @notifier.expects(:do_notify).with(wizard + 1, "Limbo").in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard + 1, regexp_matches(/You are in a dense mist/)).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard, regexp_matches(/potato is briefly visible through the mist/)).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard + 1, Phrasebook.lookup('contents')).in_sequence(notify)
      @notifier.expects(:do_notify).with(wizard + 1, "Wizard").in_sequence(notify)
      assert(!session.do_command('create potato head'), "should return false if quit isn't signalled")
      assert_equal(0, session.output_buffer.length)

      # When we are connected, unknown commands should route through to the game
      game.expects(:process_command).with(wizard + 1, 'hello')
      assert(!session.do_command('hello'), "should return false if quit isn't signalled")

      # Check create failure
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('create potato head'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/#{Phrasebook.lookup('create-fail').chomp}/, session.output_buffer[0])

      # Missing user and password
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('create'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0])

      # Missing password
      session = Session.new(@db, game, "foo", connected_players, @notifier)
      assert(!session.do_command('create bar'), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0])
    end

    def test_unconnected_unrecognized_command
      @db = Db.Minimal()
      wizard = 1
      game = mock()
      connected_players = mock()

      session = Session.new(@db, game, "foo", connected_players, @notifier)

      assert_raise RuntimeError do
        assert(!session.do_command(nil), "should return false if quit isn't signalled")
      end

      notify = sequence('notify')
      assert(!session.do_command("cheese string"), "should return false if quit isn't signalled")
      assert_equal(1, session.output_buffer.length)
      assert_match(/Welcome to TinyMUD/, session.output_buffer[0])
    end
  end
end
