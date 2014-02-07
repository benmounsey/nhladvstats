require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'
require 'pp'
require 'set'

def parse_TOI_sheet(sheet)

  doc = Nokogiri::HTML(open(sheet))
  xpath_root = '//div[@class = "pageBreakAfter"]/table[@class="tablewidth"]/tbody/tr/td/table/tbody/tr//descendant::td[contains(concat(\' \',@class,\' \'), \' playerHeading \')]'
  xpath_td = '//div[@class = "pageBreakAfter"]/table[@class="tablewidth"]/tbody/tr/td/table/tbody/tr//descendant::td[contains(concat(\'  \',@class, \'  \'), \' lborder \')  and not(contains(concat(\' \',@class, \' \'), \' heading \')) or contains(concat(\' \',@class, \' \'), \' playerHeading \') ]'
  
  #get the players on the gamesheet.
  players = Set.new()
  #get all the rows that match the root xpath
  player_sheet = doc.xpath(xpath_root).each do |player_name|
    # Fill the players set with each player row that is found, by pushing each returned node and it's node.text into the player_name array, and then adding them to the players set. 
    player_name.xpath('.//text()').map{ |node| node.text } 
    #add them to the players array
    players.add(player_name.text())
  end
  players = players.to_a()
  
#from here we have from the first playerheading -> final player's summary sheet in the doc variable.  What we want to do is look at each row.  If it's a playerHeading row, check the text in that row and set the player key to be that of the player's name in the players array.    If it's a shift row, parse it into a shift hash object, pop it into the player_shifts array and move on to the next line.  End when we encounter the end of the document or another player's name. 
 f = File.open('d:\dev\nhl\temp.txt', 'w')
 
  players.each do |player|
       	 
	  
	  f.write(player)
		#if line.text == player
			@playerkey = player
			
		#else
			#create the shift object out of the shift row
			#shift = []
			# [
			#	[:shift_num, 'td text()'],
			#	[:period, 'td[2] text()'],
			#	[:start_time,'td[3] text()'], 
			#	[:end_time, 'td[4] text()'],
			#	[:duration, 'td[5] text()'],
			#  ]	
			
		
	#end		
end		

  
  
end
  parse_TOI_sheet('D:\dev\NHL\sheets\20132014\TH020022.HTM')


  
  
    
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  