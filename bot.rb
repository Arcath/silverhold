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
