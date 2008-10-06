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
					res=@db.query("SELECT * FROM `smarts` WHERE `item` = '#{item}'")
					i=0
					res.each do |row|
						if i == 0 then
							notice("#{item}:  #{row[1]}",chan)
						elsif i <= 3 then
							notice("#{' '*(item.length + 3)}#{row[1]}",chan)
						elsif i == 4 then
							@more="#{item}*|*#{row[1]}"
							notice("There is more type \"!more\"",chan)
						elsif i >= 5 then
							@more+="*|*#{row[1]}"
						end
						i+=1
					end
				else
					notice("I dont know anything about #{item}",chan)
				end
				like=""
				put=0
				res=@db.query("SELECT * FROM `smarts` WHERE `item` LIKE '%#{item}%'")
				res.each do |row|
					if row[0] != item  and put <= 2 and !like.include? row[0] then
						put+=1
						like+="#{row[0]}, "
					end
				end
				if like != "" then
					notice("You might have been looking for #{like[0...(like.length-2)]}",chan)
				end
			end
			if msg =~ /^!mo(re|ar)$/ then
				if @more != "" then
					mores=@more.split("*|*")
					i=0
					@more=""
					mores.each do |more|
						if i == 0 then
							item=more
						elsif i == 1
							notice("#{item}:  #{more}",chan)
						elsif i <= 4
							notice("#{' '*(item.length+3)}#{more}",chan)
						elsif i == 5
							@more="#{item}*|*#{more}"
							notice("There is still more type \"!more\"",chan)
						elsif i >= 6
							@more+="*|*#{more}"
						end
						i+=1
					end
				else
					notice("There is no overflow",chan)
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
			res=@db.query("SELECT * FROM `smarts` WHERE `item` = 'alerts'")
			res.each do |row|
				lookfor=row[1].split(".")[0]
				if msg =~ /#{lookfor}/ then
					notice(row[1].split(".")[1],chan)
				end
			end
			if msg =~ /^!till / then
				event=msg.split("!till ")[1]
				s="#{nick}'s death.2010 05 09 12 00"
				res=@db.query("SELECT * FROM `smarts` WHERE `item` = 'till' AND `fact` LIKE '%#{event}.%' LIMIT 1")
				res.each do |row|
					s=row[1]
				end
				fact=s.split(".")[0]
				times=s.split(".")[1]
				date=times.split(" ")
				time=Time.mktime(date[0],date[1],date[2],date[3],date[4],date[5],0)				
				diff=time.to_i-Time.now.to_i
				notice("#{self.till(diff)} till #{fact}",chan)
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
							out = Thread.new { $SAFE=4; eval math.gsub("^","**") }.value.inspect
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
		if !(message.ping?) and @lastmsg  <= Time.now.to_i-1800 then
			notice("Welcome to #Whitefall!","#whitefall")
		end
		if message.ping?
			server=message.scan(/^PING :(.*)/).join
			send("PONG #{server}")
		else
			@lastmsg=Time.now.to_i
		end
		if message.invite?
			join=message.scan(/^\:.* \:(\#.*)\r/).join
			self.join(join)
		end
	end
end
