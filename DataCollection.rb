#Includes
require 'net/http'
require 'open-uri'
require 'fileutils'
require 'mechanize'
#require 'nokogiri'
 
 
# URLs to grab gamesheets from - 1230 games total regular season, 624 games 12-13
# Playoff Game numbers like <ROUND><MATCHUP><GAMENUM> (146 = TOR/BOS Round 1 game 6)
# Playoff round numbers:
# Round 1: 11x, 12x, 13x, 14x, 15x, 16x, 17x, 18x
# Round 2: 21x, 22x, 23x, 24x
# Round 3: 31x, 32x
# Round 4: 41x
# Gamesheets start at 20012002 season and skip 20042005.
# 1. Gamesheet: http://www.nhl.com/scores/htmlreports/20122013/GS020624.HTM
# 2. Event Summary sheet: http://www.nhl.com/scores/htmlreports/20122013/ES020624.HTM
# 3. Faceoffs: http://www.nhl.com/scores/htmlreports/20122013/FC020624.HTM
# 4. PBP: http://www.nhl.com/scores/htmlreports/20122013/PL020624.HTM
# 5. HOME TOI: http://www.nhl.com/scores/htmlreports/20122013/TH020624.HTM
# 6. VIS TOI: http://www.nhl.com/scores/htmlreports/20122013/TV020624.HTM
 
DATA_DIR = 'D:/dev/nhl/sheets'
BASE_URL = "/scores/htmlreports"
AGENTS = [
   "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6",
   "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401",
   "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10",
   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22",
   "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
   "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
   "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
   "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
  ]
 
#Check to see if our data dir exists, if not, create it.
FileUtils.mkdir_p(DATA_DIR) unless Dir.exists?(DATA_DIR)
 
def get_sheets(season, gametype)
 
#Convert the season arg to string wholesale
season = season.to_s unless season.is_a?(String)
 
num_games = 1230
num_games = 624 if season == "20122013"
num_games = 0 if (season == "20042005" || gametype.upcase == "P") # for now, only reg season
url = [] 
sheettype = %w[GS0 ES0 FC0 PL0 TH0 TV0] #whitespace array
 
#loop through each sheet-type and grab all the sheets related
        sheettype.each do |x|
          (1..num_games).each do |i|
                url[i] = "#{BASE_URL}/#{season}/#{x}#{(20000 + i)}.HTM"
            end
        scrape_url(url)
		end
 
end

def scrape_url(url) #alex's implementation
  agent = Mechanize.new
 
  #spoof the agent using the const array; choose one at random via the index
  agent.user_agent = AGENTS[Random.rand(AGENTS.length)]
 
  #only hold one request at a time
  agent.max_history = 1
  agent.follow_meta_refresh = true
  #agent.keep-alive = false
 
  #limit requests to be polite
  agent.history_added = Proc.new { sleep Random.rand(0.1).round(3) }
  (1...url.length).each do |x|
	filename = DATA_DIR + url[x].to_s
	begin
	page = agent.get(URI::unescape("http://www.nhl.com/" + url[x].to_s)).save_as filename unless File.exists?(filename)
	rescue Mechanize::ResponseCodeError
	puts "page not found"
	end
	
	end
	
  #page.parser #returns a nokogiri document
end
#get_sheets 20052006, "r"

get_sheets 20102011, "r"
