module TinyMudTest
  # Yuk :-)
  TINYMUD_HOST = "localhost"
  TINYMUD_PORT = 4201

    class Player
      def initialize(stdout, name, password, create = false, expect_fail = false)
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
			do_puts("OUTPUTPREFIX suffix")
			do_puts("OUTPUTSUFFIX > ")
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
	  def do_puts(s)
        log(s, :out)
        @session.puts(s)
	  end

      def log(s, direction)
        if direction == :out
          #s.each_line {|line| @stdout.puts "\e[31;1m#{@name}: #{line.chomp}\e[0m"}
		  s.each_line {|line| @stdout.puts "#{@name}: #{line.chomp}"}
        else
		  if s
			#s.each_line {|line| @stdout.puts "\e[32;1m#{@name}: #{line.chomp}\e[0m"}
			s.each_line {|line| @stdout.puts "#{@name}: #{line.chomp}"}
		  else
			#@stdout.puts "\e[32;1m#{@name}: no response received from server\e[0m"
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
