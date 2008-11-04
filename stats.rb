#!/usr/bin/env ruby
file=File.new("../irssilog.txt")
@nicks=[]
@posts=[]
begin
	while (line=file.readline)
		#lets get the details
		temp=line.split("<")[1]
		if temp then
			nick=temp.split(">")[0]
		end
		if !(@nicks.include? nick) then
			@nicks.push(nick)
		end
		if nick then
			i=0
			while i<=@nicks.nitems-1 do
				if @nicks[i]==nick
					if @posts[i] then
						@posts[i]+=1
					else
						@posts[i]=1
					end
				end
				i+=1
			end
		end
	end
rescue EOFError
	file.close
end
puts @nicks
puts @postsc
