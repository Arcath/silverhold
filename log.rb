class Bot
	def log(nick,s)
		if s[1] != "!" then
			@db.query("INSERT INTO `log` (`time`,`nick`,`s`) VALUES ('#{Time.now.to_i}','#{nick}','#{s.gsub("'","&#39").gsub('"',"&#34")}');")
		end
	end
end
