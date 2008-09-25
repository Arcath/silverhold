class String
	def privmsg?
		self=~/^\:.*!.*\@.*PRIVMSG\ .* \:.*/
	end
	def part?
		self=~/^\:.*!.*\@.*PART\ \#.*/
	end
	def quit?
		self=~/^\:.*!.*\@.*QUIT\ :.*/
	end
	def join?
		self=~/^\:.*!.*\@.*JOIN\ :\#.*/
	end
	def op?
		self=~/^\:.*!.* MODE \#.* \+o .*/
	end
	def deop?
		self=~/^\:.*!.* MODE \#.* \-o .*/
	end
	def invite?
		self=~/^\:.*!.* INVITE .* \:.*/
	end
	def ping?
		self=~/^PING :.*/
	end
end
class Fixnum
	def standardForm(num = 3)
		"%.#{num}e" % self
	end
end
class Bot
	def parse
		message=self.recv
		if message.privmsg?
			msg=message.split(/\:/,3)[2].sub("\r\n",'')
			nick=message.split(/\!/)[0].sub(/^\:/,'')
			chan=message.scan(/.* PRIVMSG (.*) \:.*/).join
			if chan == @nick
				chan=message.scan(/^\:(.*)!.*@.*/).join
			end
			#Functions here (e.g. !help)
			if msg =~ /^!help/ then
				if @admin.include? nick or @moderator.include? nick
					if @admin.include? nick
						s="an administrator"
					else
						s="a moderator"
					end
					if not identified nick
						s2="You are unidentified, as a result will be unable to use commands"
					end
					notice("You are #{s}. to add to the db !add item, fact to remove !remove item, fact. #{s2}",chan)
				else
					notice("Query the Database using !about item",chan)
				end
			end
			if msg =~ /^!admins/ then
				notice("Bot Administrators:",chan)
				@admin.each do |admin|
					notice(admin,chan)
				end
			end
			if msg =~ /^!mods/ then
				notice("Bot Moderators:",chan)
				@moderator.each do |mod|
					notice(mod,chan)
				end
			end
			if msg =~ /^!time/ then
				t=Time.now
				notice("The time is: #{t}",chan)
			end
			if msg =~ /^!addadmin/ then
				if @admin.include? nick and identified nick
					add=msg.split("!addadmin ")[1]
					if @admin.include? add then
						notice("#{add} is already an administrator",chan)
					else
						if @db.has(add,'staff','name') == 1
							@db.query("UPDATE `staff` SET `type` = 'admin' WHERE `name` = '#{add}'")
							@moderator.delete(add)
						else
							@db.query("INSERT INTO `staff` (`name`,`type`) VALUES ('#{add}','admin')")
						end
						notice("#{add} is now an administrator",chan)
						@admin.push(add)
					end
				end
			end
			if msg =~ /^!deadmin/ then
				if @admin.include? nick and identified nick
					rem=msg.split("!deadmin ")[1]
					@db.query("DELETE FROM `staff` WHERE `name` = '#{rem}' AND `type` = 'admin'")
					@admin.delete(rem)
					notice("#{rem} is no longer an administrator",chan)
				end
			end
			if msg =~ /^!addmod/ then
				if @admin.include? nick and identified nick
					add=msg.split("!addmod ")[1]
					if @moderator.include? add then
						notice("#{add} is already a moderator",chan)
					else
						if @db.has(add,'staff','name') == 1
							@db.query("UPDATE `staff` SET `type` = 'mod' WHERE `name` = '#{add}")
							@admin.delete(add)
						else
							@db.query("INSERT INTO `staff` (`name`,`type`) VALUES ('#{add}','mod')")
						end
						notice("#{add} is now a moderator",chan)
						@moderator.push(add)
					end
				end
			end
			if msg =~ /^!demod/ then
				if @admin.include? nick and identified nick
					rem=msg.split("!demod ")[1]
					@db.query("DELETE FROM `staff` WHERE `name` = '#{rem}' AND `type` = 'mod'")
					@moderator.delete(rem)
					notice("#{rem} is no longer a moderator",chan)
				end
			end
			if msg =~ /^!add / then
				if @admin.include? nick or @moderator.include? nick and identified nick
					temp=msg.split("!add ")[1]
					item=temp.split(", ")[0]
					fact=temp.split(", ")[1]
					@db.query("INSERT INTO `smarts` (`item`,`fact`) VALUES ('#{item}','#{fact}')")
					notice("I'll Remember That!",chan)
				else
					notice("You do not have permission to add to the database",chan)
				end
			end
			if msg =~ /^!about/ then
				item=msg.split("!about ")[1]
				if @db.has(item,'smarts','item')==1
					notice("#{item}:",chan)
					res=@db.query("SELECT * FROM `smarts` WHERE `item` = '#{item}'")
					res.each do |row|
						notice(row[1],chan)
					end
				end
			end
			if msg=~ /^!remove/ then
				if @admin.include? nick or @moderator.include? nick and identified nick
					temp=msg.split("!remove ")[1]
					item=temp.split(", ")[0]
					fact=temp.split(", ")[1]
					if fact != ""
						@db.query("DELETE FROM `smarts` WHERE `item` = '#{item}' AND `fact` = '#{fact}'")
						notice("Forgot!",chan)
					else
						notice("Syntax Error",chan)
					end
				end
			end
			alerts=[]
			res=@db.query("SELECT * FROM `smarts` WHERE `item` = 'alerts'")
			res.each do |row|
				lookfor=row[1].split(".")[0]
				if msg =~ /#{lookfor}/ then
					notice(row[1].split(".")[1],chan)
				end
			end
			if msg=~ /^!wiki/ then
				string=msg.split("!wiki ")[1]
				
			end
			if msg=~/stop!/ or msg=~/^Silverhold: stop/ then
				notice("HAMMER TIME",chan)
			end
			if msg=~/^!math/ then
				math=msg.split("!math ")[1]
				i = Math.sqrt(-1)
				everything = 42
				leet = 1337
				begin
					if math =~ /sleep/ or math =~ /eval/ or math =~ /Thread/ or math =~ /Timeout/
						out = "Invalid Command"
					else
						Timeout::timeout(1) {
							out = Thread.new { $SAFE=4; eval math }.value.inspect
						}
					end
					if out.length > 400
						if out.class == Integer
							out = out.standardForm(10)
						else
							out = out[0..400].to_s + '...'
						end
					end
				rescue SyntaxError
					out = "Syntax Error"
				rescue SecurityError
					out = "Insecure Operation"
				rescue ZeroDivisionError
					out = "Division By 0"
				rescue Timeout::Error
					out = "Timeout"
				rescue => error
					out = "Error #{error}"
				end
				notice(out,chan)
			end
		end
		if message.ping?
			server=message.scan(/^PING :(.*)/).join
			send("PONG #{server}")
		end
	end
end
