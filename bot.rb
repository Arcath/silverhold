#!/usr/bin/env ruby
#Class Based IRC Bot
require "mysql"
require "mathn"
require 'db'
require 'irc'
require 'parse'
require 'timeout'

class Bot
	include Math
	def initialize(nick,host,name,admin,moderator,db)
		@nick=nick
		@host=host
		@name=name
		@admin=admin
		@moderator=moderator
		@db=db
		puts "#{@nick} initialised"
	end
	def till(stamp)
		years=(stamp/31536000).to_i
		months=((stamp-(years*31536000))/2628000).to_i
		days=((stamp-(years*31536000)-(months*2628000))/86400).to_i
		hours=((stamp-(years*31536000)-(months*2628000)-(days*86400))/3600).to_i
		minutes=((stamp-(years*31536000)-(months*2628000)-(days*86400)-(hours*3600))/60).to_i
		seconds=stamp-(years*31536000)-(months*2628000)-(days*86400)-(hours*3600)-(minutes*60)
		s=""
		if years != 0 then
			s=s+"#{years} Years "
		end
		if months != 0 then
			s=s+"#{months} Months "
		end
		if days != 0 then
			s=s+"#{days} Days "
		end
		if hours != 0 then
			s=s+"#{hours} Hours "
		end
		if minutes != 0 then
			s=s+"#{minutes} Minutes "
		end
		if seconds != 0 then
			s=s+"#{seconds} Seconds"
		end
		return s
	end
end

nick=@db.getvalue(1,'system','field','nick')
pass=@db.getvalue(1,'system','field','pass')
host=@db.getvalue(1,'system','field','host')
name=@db.getvalue(1,'system','field','name')
server=@db.getvalue(1,'system','field','server')
chan=@db.getvalue(1,'system','field','chan')

admins=[]
res=@db.query("SELECT * FROM `staff` WHERE `type` = 'admin'")
res.each do |row|
	admins.push(row[0])
end

mods=[]
res=@db.query("SELECT * FROM `staff` WHERE `type` = 'mod'")
res.each do |row|
	mods.push(row[0])
end

bot=Bot.new(nick,host,name,admins,mods,@db)
bot.connect(server)
bot.identify(pass)
bot.join(chan)
while 1
	bot.parse
end
