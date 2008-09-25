class Bot
	def send(s)
		s=s.gsub(/\n/,'').gsub(/\r/,'')
		@con.send(s +"\n", 0)
	end
	def connect(server,port=6667)
		@server=server
		@port=port
		puts "Connecting to #{@server} on port #{@port}"
		@con=TCPSocket.new(@server,@port)
		send("USER " + @nick + " " + @host + " bla :" + @name)
		send("NICK " + @nick)
		msg=@con.recv(512)
		while msg !~ /^:.* 001.*/
			puts msg
			if msg =~ /Nickname is already in use/
				@nick=@nick+"_"
				send("NICK " + @nick)
			end
			msg=@con.recv(512)
		end
		puts "Connected as #{@nick}"
	end
	def disconnect
		@con.close
	end
	def recv
		@con.recv(512)
	end
	def identify(pass)
		self.send("PRIVMSG NickServ :IDENTIFY #{pass}")
		msg=self.recv
		puts msg
		while msg !~ /901/
			msg=self.recv
			puts msg
		end
		puts "Identified as #{@nick}"
	end
	def join(chan)
		self.send("JOIN #{chan}")
		puts "JOINED #{chan}"
	end
	def part(chan)
		self.send("PART #{chan}")
		puts "LEFT #{chan}"
	end
	def notice(msg,chan)
		self.send("NOTICE #{chan} :#{msg}")
	end
	def identified(nick)
		send "WHOIS #{nick}"
		whois=@con.recv 512
		whois =~ /320 #{@nick} #{nick}/
	end
end
