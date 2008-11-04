class Bot
	def stats(nick,chan)
		total=0
		lols=0
		res=@db.query("SELECT * FROM `log` WHERE `nick` = '#{nick}'")
		res.each do |row|
			total+=1
			if row[2] =~ /^lol/ then
				lols+=1
			end
		end
		s="#{nick}: "
		a=" "*s.length
		notice("#{s} Total: #{total}",chan)
		notice("#{a} Lols: #{lols}",chan)
	end
end
