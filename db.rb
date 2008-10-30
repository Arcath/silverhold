class Mysql
	def getvalue(want,table,idfield,idvalue)
		res=self.query("SELECT * FROM `#{table}` WHERE `#{idfield}` = '#{idvalue}' LIMIT 1")
		res.each do |row|
			@out=row[want]
		end
		return @out
	end
	def has(want,table,field)
		count=0
		res=self.query("SELECT * FROM `#{table}` WHERE `#{field}` = '#{want}' LIMIT 1")
		res.each do |row|
			count=count+1
		end
		return count
	end
end

@db=Mysql::new("127.0.0.1","bot","dyton","bot")
