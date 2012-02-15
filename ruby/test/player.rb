module TinyMudTest
  # Yuk :-)
  TINYMUD_HOST = "localhost"
  TINYMUD_PORT = 4201

  class Player
    def initialize(stdout, name, password, create = false, expect_fail = false)
      # some of this needs explaining!
      # In order to ensure we parse commands back from the server we hook into
      # un-documented TinyMUD commands, OUTPUTPREFIX and OUTPUTSUFFIX.
      # OUTPUTSUFFIX is the key, by setting it to a known value we can get the
      # telnet class to look out for the suffix and recognise the end of a command
      # response (see initialization of the telnet class below). BUT you need to
      # be logged on to set these commands, some of the tests fail before logon
      # and in these cases we just put text and wait for a response string
      # which should be the whole response - our IO buffers should be large
      # enough to eat the whole response in one go.
      @stdout = stdout
      @name = name
      @session = new_session(TINYMUD_HOST, TINYMUD_PORT)
      log(@session.waitfor(/.*\n/), :in)
      if create
        do_puts("create #{name} #{password}")
      else
       do_puts("connect #{name} #{password}")
      end
      log(@session.waitfor(/.*\n/), :in)
      if expect_fail
        do_puts("QUIT")
        log(@session.waitfor(/.*\n/), :in)
      else
        do_puts("OUTPUTPREFIX suffix", false)
        do_puts("OUTPUTSUFFIX > ", false)
      end
    end
    
    def cmd(action, logout = true, strip_db_numbers = false)
      log(action, :out) if logout
      @session.cmd(action) do |response|
        if logout
          if strip_db_numbers
            response.gsub!(/#\d+/, '')
          end
          log(response, :in)
        end
      end
    end
  
    def who()
      do_puts("WHO")
      log(@session.waitfor(/.*\n/), :in)
    end
    
    def quit()
      cmd("QUIT")
    end
    
    def shutdown()
      cmd("@shutdown")
    end
    
  private
    def do_puts(s, logout = true)
      log(s, :out) if logout
      @session.puts(s)
    end
    
    def log(s, direction)
      if direction == :out
        s.each_line {|line| @stdout.puts "(tx) #{@name}: #{line.chomp}"}
      else
        if s
          s.each_line {|line| @stdout.puts "(rx) #{@name}: #{line.chomp}"}
        else
          @stdout.puts "#{@name}: no response received from server"
        end
      end
    end

    def new_session(host, port)
      begin
        Net::Telnet.new('Host' => host, 'Port' => port, 'Prompt' => /> \n/n)
      rescue Errno::ECONNREFUSED => e
        @stdout.puts "Failed connecting: #{e}"
      end
    end
  end
end
