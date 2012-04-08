require 'time'
require_relative 'player'
require_relative 'look'
require_relative 'phrasebook'

module MangledMud

  # Represents a players "session" with the game. It handles commands issued before a player
  # has actually been created or connected with the game and routing all the players input commands and
  # the resulting output text before and after they are connected. It essentially adds session management
  # to {Game}
  #
  # @see Server
  # @see Game
  # @version 1.0
  class Session
    # @return [Number] The database id of the connected player this session represents, nil if not connected
    attr_reader :player_id
    
    # @return [Time] The last time the player interacted with the game, nil if never
    attr_reader :last_time

    # @return [Array of String] The current buffer of lines to write back to the player see {#process_input}
    attr_accessor :output_buffer

    # @note although descriptor_details implies a socket, this is not the case, it is just something representing the outer container's connection to this
    # @param [Db] db the current database instance
    # @param [Game] game the current game instance
    # @param [Object] descriptor_details an object representing the external connection to the session, must support to_s() for logging
    # @param [Function] connected_players a function which when invoked will return an array of currently connected player identifiers
    def initialize(db, game, descriptor_details, connected_players)
      @db = db
      @game = game
      @descriptor_details = descriptor_details
      @connected_players = connected_players

      @player_id = nil
      @last_time = nil
      @input_buffer = ""
      @output_prefix = nil
      @output_suffix = nil
      @output_buffer = []

      @game.add_observer(self)

      welcome_user()
    end

    # This is an internal callback, but has to be public to allow Observable callbacks -
    # It gets all messages from {Game} and filters out those destined for this player.
    #
    # @param [Number] player_id the id of the player being updated
    # @param [String] message the message being sent to the player
    def update(player_id, message)
      # Only queue messages for this player (game broadcasts to all observing sessions).
      # Note: Because the db has no concept of a logged off player, messages can be sent
      # to players who are in a room etc. but not connected!
      queue(message) if (@player_id == player_id)
    end

    # Push a string into the session's command input queue. If the string and previously pushed text forms at
    # least one command i.e. text delimited by a line ending then a call to {#process_input} will result
    # in the command being applied by this player. You may queue any number of
    # commands, or partial commands through this method and call {#process_input} to
    # attempt to execute them. E.g. queue_input("text1EOLtext2EOLtext3") would result
    # in two {#process_input} calls executing  text1 and text2, until an EOL is queued
    # further {#process_input} calls will not initiate the text3 command.
    #
    # @param [String] s part of, one or many commands to be processed by {#process_input}
    def queue_input(s)
      @input_buffer << s unless s.nil?
    end

    # If the session has at least one full command queued (see {#queue_input}), then
    # execute it. Calling this clears the {#output_buffer} regardless of whether a command
    # was executed or not. Before calling it is up to the callee to write out the {#output_buffer}.
    #
    # @return [[Number, Boolean]] the number of remaining full commands in the input queue and an indication if the player has quit the session as a result of executing a buffered "quit" command.
    # @see #queue_input
    def process_input()
      @output_buffer = []
      command, eol, remainder = @input_buffer.partition(/\r{,1}\n/)
      player_quit = false
      unless eol.empty?
        @input_buffer = remainder
        player_quit = do_command(command)
      end
      [@input_buffer.scan(/.*?\r{,1}\n/).length, player_quit]
    end

    # Inform this session it is shutting down. This writes a shutdown message to
    # the {#output_buffer} and causes the session to stop observing {Game}.
    def shutdown()
      wrap_command(->() { queue(Phrasebook.lookup('shutdown-message')) })
      @game.delete_observer(self)
    end

    private

    # Process a command from this player. This causes the {#output_buffer} to be filled with a response (or responses).
    def do_command(command)
      @last_time = Time.now()
      @output_buffer = []
      has_player_quit = false

      command.chomp!()
      case
      when (command.strip() == Phrasebook.lookup('quit-command'))
        player_quit()
        has_player_quit = true
      when (command.strip() == Phrasebook.lookup('who-command'))
        wrap_command(->() { dump_users() })
      when (command.start_with?(Phrasebook.lookup('prefix-command')))
        @output_prefix = command[Phrasebook.lookup('prefix-command').length + 1..-1]
        queue(Phrasebook.lookup('done-fix'))
      when (command.start_with?(Phrasebook.lookup('suffix-command')))
        @output_suffix = command[Phrasebook.lookup('suffix-command').length + 1..-1]
        queue(Phrasebook.lookup('done-fix'))
      else
        if @player_id
          wrap_command(->() { @game.process_command(@player_id, command) })
        else
          check_connect(command)
        end
      end

      has_player_quit
    end

    # Queue (push onto the output buffer) the given message
    def queue(message)
      @output_buffer << normalize_line_endings_for_transmission(message) unless message.empty?
    end

    # See if the given message (should be command) causes a player to "connect" to the game
    def check_connect(message)
      command, user, password = parse_connect(message)
      if command
        case
        when command.start_with?("co")
          connect_player(user, password)
        when command.start_with?("cr")
          create_player(user, password)
        else
          welcome_user()
        end
      else
        welcome_user()
      end
    end

    # Queue a welcome message
    def welcome_user()
      queue(Phrasebook.lookup('welcome-message'))
    end

    # Queue a good bye message
    def goodbye_user()
      wrap_command(->() { queue(Phrasebook.lookup('leave-message')) })
    end

    # Attempt to connect a player, given their user name and password
    def connect_player(user, password)
      connected_player = @game.connect_player(user, password)
      if connected_player == NOTHING
        queue(Phrasebook.lookup('connect-fail'))
        puts "FAILED CONNECT #{user} on descriptor #{@descriptor_details}"
      else
        puts "CONNECTED #{@db[connected_player].name}(#{connected_player}) on descriptor #{@descriptor_details}"
        @player_id = connected_player
        @game.process_command(connected_player, "look")
      end
    end

    # Attempt to create a new player, given a user name and password
    def create_player(user, password)
      new_player = @game.create_player(user, password)
      if new_player == NOTHING
        queue(Phrasebook.lookup('create-fail'))
        puts "FAILED CREATE #{user} on descriptor #{@descriptor_details}"
      else
        puts "CREATED #{@db[new_player].name}(#{new_player}) on descriptor #{@descriptor_details}"
        @player_id = new_player
        @game.process_command(new_player, "look")
      end
    end

    # Handle the player quit-ing
    def player_quit()
      goodbye_user()
      if @player_id
        puts "DISCONNECTED #{@db[@player_id].name} #{@descriptor_details}"
      else
        puts "DISCONNECTED #{@descriptor_details}"
      end
    end

    # Handle the "who" command
    def dump_users()
      now = Time.now()
      queue(Phrasebook.lookup('current-players'))
      connected_players = @connected_players.call()
      connected_players.each do |connected_player|
        if connected_player.last_time
          queue("#{@db[connected_player.player_id].name} idle #{(now - connected_player.last_time).to_i} seconds")
        else
          queue("#{@db[connected_player.player_id].name} idle forever")
        end
      end
    end

    # Simple parser for commands available before connecting to game
    def parse_connect(message)
      message.strip!
      match = /^([[:graph:]]+)\s+([[:graph:]]+)\s+([[:graph:]]+)/.match(message)
      match ? match[1..3] : []
    end

    # All line endings are telnet friendly
    def normalize_line_endings_for_transmission(s)
      s.chomp().gsub("\n", "\r\n") + "\r\n"
    end

    # Handle addition of pre and post fix text to command responses
    def wrap_command(command)
      # Some commands, @shutdown for example, do not generate any output. To stop
      # sending empty data back we detect this and drop the buffer content if the
      # command produced nothing (didn't extend the output queue) - Yuk...
      queue(@output_prefix) if @output_prefix
      old_output_buffer_length = @output_buffer.length
      command.call()
      if @output_buffer.length == old_output_buffer_length
        @output_buffer.pop() if @output_prefix
      else
        queue(@output_suffix) if @output_suffix
      end
    end
  end
end
