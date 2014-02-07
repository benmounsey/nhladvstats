require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'
require 'pp'
=begin
TODO: Add exception handling
TODO: Look for optimization to improve perf -
TODO: 
=end
def parse_game_info(sheet)
#instantiate a nokogiri data object with the play-by-play sheet
doc = Nokogiri::HTML(open(sheet))
#grab the blocks which contain the header for the gamesheet
visitorinfo = doc.css('#Visitor>tbody')
homeinfo = doc.css('#Home>tbody')
gameinfo = doc.css('#GameInfo>tbody')
 
game = {
 
                :visitor => visitorinfo.at_css('tbody>tr[3]>td text()'),
                :home => homeinfo.at_css('tbody>tr[3]>td text()'),
                :visitor_score => visitorinfo.at_css('tbody>tr>td>table>tbody>tr>td[2] text()'),
                :home_score => homeinfo.at_css('tbody>tr>td>table>tbody>tr>td[2] text()'),
                :game_date => gameinfo.at_css('tbody>tr[4]>td text()'),
                :game_audience => gameinfo.at_css('tbody>tr[5]>td text()').text.gsub("\u00A0", ' '),
                :attendance => gameinfo.at_css('tbody>tr[5]>td text()').text.scan(/([0-9\,])/).join,
               
        }
f = File.open('D:\dev\debugging\temp.txt', 'w')
f.write(game.to_json)
        game
       
end


def parse_PL_sheet(sheet)
#instantiate a nokogiri data object with the play-by-play sheet
  doc = Nokogiri::HTML(open(sheet))
  #remove all the br tags from within the document.
  doc.search('br').each { |br| br.replace(" ") }
  
  rows = []
  rows = doc.css('table.tablewidth tr.evenColor')
  #start_time = Time.now //benchmarking
  #get a collection of all the rows that we're interested in 
  events = rows.collect do |row|
	#create a hash with the values from each row stored within it.
	event = {}
	[
	  [:shift_num, 'td'],
	  [:period, 'td[2]'],
	  [:strength,'td[3]'], 
	  [:time, 'td[4] text()'],
	  [:e_type, 'td[5]'],
	  [:description, 'td[6]'],  #TODO: this field will need to be chopped up to handle the different event types; 
	  	  
	 ].each do |num, css|
	event[num] = row.at_css(css).text.gsub("\u00A0", ' ') # replace any non-breaking spaces with blanks
	
	end
		
	newvals = splitdsc(event[:e_type], event[:description], event[:period]) 
	event.merge!(newvals) unless newvals.empty? 
	event
  end
  #exec_time = Time.now - start_time
  #puts "execution time was #{exec_time} seconds."
  
  #debug - print the hash to file so we can inspect the results
  f = File.open('D:\dev\debugging\temp.txt', 'a')
  #events.each do |x|
  #f.puts(x[:e_type] + "  ^  " + x[:description])
 
  
  f.write(events.to_json)
  #f.write(doc.css)

end
#take the event type and the description text, then return split up values in an array
def splitdsc(e_type, dsc, period)
detail = {}
=begin 
   :team_actor
   :team_actee
   :actor
   :actor_num
   :actee
   :actee_num
   :shot_type
   :zone
   :shot_location
   :distance
   :actee
   :a1
   :a1_num
   :a2
   :a2_num
   :penalty
   :penalty_duration
=end
  detail[:description] = dsc.dup
  
  case e_type
	
    when 'GIVE'
    #[GTM] GIVEAWAY - [#XX Player], [Zone]
    detail[:team_actor] = dsc.slice(0..2)
	detail[:actor] = dsc.slice(dsc.index("#")..(dsc.index(",")-1))
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:zone] = dsc.slice(dsc.index(",")+2, dsc.length)
	return detail
	
    when 'HIT'
    #[HTT] [#XX PLAYER] HIT [RTT] [#XX PLAYER], [Zone]
	detail[:team_actor] = dsc.slice(0..2)
	detail[:actor] = dsc.slice(dsc.index("#")..(dsc.index("HIT")-2)).strip
	#detail[:actor] = dsc.slice!(dsc.match(/[#]\d\s.\w*/).to_s)
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:team_actee] = dsc.slice(dsc.index("HIT")+3...dsc.index("HIT")+7).strip
	detail[:actee] = dsc.slice(dsc.index("#",dsc.index("HIT"))..dsc.index(",", dsc.index("HIT"))-1).strip
	
	#detail[:actee] = dsc.slice!(dsc.match(/[#]\d\s.\w*/).to_s)
	detail[:actee_num] = detail[:actee].slice!(detail[:actee].index("#")...detail[:actee].index(/\s/)+1).strip.delete!'#'
	detail[:zone] = dsc.slice(dsc.rindex(",")+1...dsc.length).strip
    return detail

 
    when 'BLOCK'
    #[STM] [#XX PLAYER] BLOCKED BY [BTM] [# XX BLOCKER], [Shot_type], [Zone] 
	detail[:team_actee] = dsc.slice(0..2)
	#detail[:actee] = dsc.slice!(dsc.match(/[#]\d\s.\w*?/).to_s)
	detail[:actee] = dsc.slice!(dsc.index("#")..(dsc.index("BLOCKED")-1)).strip
	detail[:actee_num] = detail[:actee].slice!(detail[:actee].index("#")...detail[:actee].index(/\s/)+1).strip.delete!'#'
	detail[:team_actor] = dsc.slice!(dsc.index("D BY ")+6...dsc.index("D BY ")+9).strip
	#detail[:actor] = dsc.slice!(dsc.match(/[#]\d\s.\w*?/).to_s)
	detail[:actor] = dsc.slice!(dsc.index("#", dsc.index("BLOCKED"))..dsc.index(",", dsc.index("BLOCKED BY"))-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:shot_type] = dsc.slice!(dsc.index(",")+2...dsc.rindex(",")).strip
	detail[:zone] = dsc.slice!(dsc.rindex(",")+1...dsc.length).strip
	return detail
		
	when 'GOAL'
	#[STM] [#XX PLAYER](#), [Type], [Zone], [Distance]. Assists: {[#XX PLAYER](#); [#XX PLAYER](#)}
	#
	
	begin
	detail[:team_actor] = dsc.slice!(0..2)
	if period == '5' #shootouts are period 5 in regular season --- TODO: UPDATE CONDITIONAL TO HANDLE PLAYOFFS
	detail[:actor] = dsc.slice!(dsc.index("#")..(dsc.index(",")-1))
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	else
	detail[:actor] = dsc.slice!(dsc.index("#")..(dsc.index("\(")-1))
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	end
	detail[:shot_type] = dsc.slice!(dsc.index(", ")+1...dsc.index(",", dsc.index(",")+1)).strip
	detail[:zone] = dsc.slice!(dsc.index(",,")+2..dsc.index((/\d/), dsc.index(","))-3 ).strip
	detail[:distance] = dsc.slice!(dsc.index((/\d/),dsc.index(","))..dsc.index(".")).strip
	begin
	detail[:A1] = dsc.slice!(dsc.index(":")+1...dsc.index("\(", dsc.index(":"))).strip
	detail[:A1_num] = detail[:A1].slice!(detail[:A1].index("#")...detail[:A1].index(/\s/)+1).strip.delete!'#'
	rescue
	detail[:A1] = ""
	detail[:A1_num] = ""
	end
	begin
	detail[:A2] = dsc.slice!(dsc.index("\;")+1...dsc.index("\(", dsc.index("\;")-1)).strip
	detail[:A2_num] = detail[:A2].slice!(detail[:A2].index("#")...detail[:A2].index(/\s/)+1).strip.delete!'#'
	rescue 
	detail[:A2] = ""
	detail[:A2_num] = ""
	end
	rescue
	return detail
	end
	return detail	

    when 'TAKE'
	#[TTM] TAKEAWAY - [#XX PLAYER], [Zone]
    detail[:team_actor] = dsc.slice(0..2)
	detail[:actor] = dsc.slice(dsc.index("#")..(dsc.index(",")-1)).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:zone] = dsc.slice(dsc.index(",")+2, dsc.length).strip
    return detail
	
	when 'SHOT'
	#[STM][LOCATION] - [#XX PLAYER], [Type], [Zone], [Distance] --- LOCATION is always ONGOAL - ignore
    detail[:team_actor] = dsc.slice(0..2)
	detail[:actor] = dsc.slice!(dsc.index("#")..dsc.index(",")-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:shot_type] = dsc.slice!(dsc.index(",")+1...dsc.index(",", dsc.index(",")+1)).strip
	detail[:zone] = dsc.slice!(dsc.index(",,")+2..dsc.index((/\d/), dsc.index(","))-3 ).strip
	detail[:distance] = dsc.slice!(dsc.index((/\d/),dsc.index(","))..dsc.index(".")).strip
	return detail
	
    when 'MISS'
 	#[MTM] [#XX PLAYER], [Type], [Where_miss], [Zone], [Distance]
	detail[:team_actor] = dsc.slice!(0..2)
	detail[:actor] = dsc.slice!(dsc.index("#")..dsc.index(",")-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:shot_type] = dsc.slice!(dsc.index(",")+1...dsc.index(",", dsc.index(",")+1)).strip
	detail[:shot_location] = dsc.slice!(dsc.index(",,")+2...dsc.index(",", dsc.index(",,")+2)).strip
	detail[:zone] = dsc.slice!(dsc.index(",,,")+4...dsc.index((/\d/), dsc.index(",,,"))-2).strip
	detail[:distance] = dsc.slice!(dsc.index((/\d/),dsc.index(","))..dsc.index(".")).strip
	return detail
	
    when 'FAC'
    #[WTM] won [ZONE] - [VTM] [#XX VPLAYER] vs [HTM] [#XX HPLAYER]  
=begin
	in this structure, the visiting team's player is always shown first, then the home team's player.
	fac_win_team = [WTM]
	actee = [#XX VPLAYER]
	team_actee = [VTM]
	actor = [#XX HPLAYER]
    team_actee = [HTM]
	
=end
	detail[:fac_win_team] = dsc.slice!(0..2)
	detail[:zone] = dsc.slice!(dsc.index("won")+3..dsc.index("-")-1).strip
    detail[:team_actee] = dsc.slice!(dsc.index("-")+1...dsc.index("#")).strip
	detail[:actee] = dsc.slice!(dsc.index("#")..dsc.index("vs")-1).strip
	detail[:actee_num] = detail[:actee].slice!(detail[:actee].index("#")...detail[:actee].index(/\s/)+1).strip.delete!'#'
	detail[:team_actor] = dsc.slice!(dsc.index("vs")+3...dsc.index("#")).strip
	detail[:actor] = dsc.slice!(dsc.rindex("#")..-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	
	return detail
	
	when 'PENL'
    #[PTM] [#XX PLAYER] [PenType](Dur), [Location] Drawn By: [ATM] [#XX Drawn by PLAYER]
=begin
	in this structure:
	team_actor = [PTM]
	actor = [#XX PLAYER]
	pen_type = [PenType]
	duration = (Dur)
	zone = location
	team_actee = [ATM]
	actee = [#XX Drawn By Player]
	
	NOTE - Investigate and handle multiple penalties in same pbp line - what if BOARDING (5 min) MISCONDUCT (10 min) for example? need to see gamesheet for example here
	bench minors dont' have a zone, this causes us to choke
	This works better now but need to handle most cases. 
	need also to handle names with spaces in them: VAN RIEMSDYK for example. 
=end
	begin
	if dsc.include?("TEAM")
	detail[:team_actor] = dsc.slice!(0..2)
	detail[:actor] = dsc.slice!(dsc.index("#")..dsc.index(",")-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:duration] = dsc.slice!((dsc.rindex("\(")+1)...dsc.rindex("\)")).strip
	detail[:pen_type] = dsc.slice!(dsc.rindex("TEAM")...dsc.rindex("\(")).strip #check this
	detail[:zone] = "Bench"
	detail[:team_actee] = "TEAM"
	detail[:actee] = "TEAM"
	detail[:actee_num] = "0"
	else
	detail[:team_actor] = dsc.slice!(0..2)
	detail[:actor] = dsc.slice!(dsc.index("#")..dsc.index(",")-1).strip
	detail[:actor_num] = detail[:actor].slice!(detail[:actor].index("#")...detail[:actor].index(/\s/)+1).strip.delete!'#'
	detail[:duration] = detail[:actor].slice!(detail[:actor].rindex("\(")..detail[:actor].rindex("\)")).strip.delete!'()'
	detail[:pen_type] = detail[:actor].slice!(detail[:actor].index(/\s/)..-1).strip
	detail[:zone] = dsc.slice!(dsc.index(",")+1...dsc.index("Drawn")).strip
		
	detail[:team_actee] = dsc.slice!(dsc.index(":")+1...dsc.index("#")).strip
	detail[:actee] = dsc.slice!(dsc.index("#")..-1)
	detail[:actee_num] = detail[:actee].slice!(detail[:actee].index("#")...detail[:actee].index(/\s/)+1).strip.delete!'#'
	end
	rescue
	return detail
	end
	
	return detail
	
	#when 'STOP'
	#
    
	when 'PSTR' || 'PEND' || 'GEND' || 'STOP'
	return detail

end
return detail
end


parse_game_info('D:\dev\repos\nhlstats\sheets\20132014\PL020022_TEST.HTM')
#parse_PL_sheet('D:\dev\repos\nhlstats\sheets\20132014\PL020022.HTM')  
parse_PL_sheet('D:\dev\repos\nhlstats\sheets\20132014\PL020022_TEST.HTM') 


