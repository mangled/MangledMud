require 'time'
require_relative 'player'
require_relative 'look'
require_relative 'phrasebook'

module MangledMud

  # Represents a players session (connected and unconnected)
  class Session
    attr_accessor :player_id, :last_time, :output_buffer

    def initialize(db, game, descriptor_details, connected_players)
      @db = db
      @game = game
      @descriptor_details = descriptor_details
      @connected_players = connected_players

      @player_id = nil
      @last_time = nil
      @output_prefix = nil
      @output_suffix = nil
      @output_buffer = []

      @game.add_observer(self)

      welcome_user()
    end

    # Observer callback from game. Has to be public :-(
    def update(player_id, message)
      # Only queue messages for this player (game broadcasts to all observing sessions).
      # Note: Because the db has no concept of a logged off player, messages can be sent
      # to players who are in a room etc. but not connected!
      queue(message) if (@player_id == player_id)
    end

    def do_command(command)
      @last_time = Time.now()
      @output_buffer = []
      has_player_quit = false

      raise "Error: command cannot be nil" if command.nil?

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

    def shutdown()
      # Note, this will dump a players current output queue, but, given the game is going down, who cares?
      @output_buffer = []
      wrap_command(->() { queue(Phrasebook.lookup('shutdown-message')) })
      @game.delete_observer(self)
    end

    private

    def queue(message)
      @output_buffer << normalize_line_endings_for_transmission(message) unless message.empty?
    end

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

    def welcome_user()
      queue(Phrasebook.lookup('welcome-message'))
    end

    def goodbye_user()
      wrap_command(->() { queue(Phrasebook.lookup('leave-message')) })
    end

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

    def player_quit()
      goodbye_user()
      if @player_id
        puts "DISCONNECTED #{@db[@player_id].name} #{@descriptor_details}"
      else
        puts "DISCONNECTED #{@descriptor_details}"
      end
    end

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

    def parse_connect(message)
      message.strip!
      match = /^([[:graph:]]+)\s+([[:graph:]]+)\s+([[:graph:]]+)/.match(message)
      match ? match[1..3] : []
    end

    def normalize_line_endings_for_transmission(s)
      s.chomp().gsub("\n", "\r\n") + "\r\n"
    end

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
