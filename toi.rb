require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'
require 'pp'
require 'set'

def parse_TOI_sheet(sheet)
 
  doc = Nokogiri::HTML(open(sheet))
  xpath_root = '//div[@class = "pageBreakAfter"]/table[@class="tablewidth"]/tbody/tr/td/table/tbody/tr//descendant::td[contains(concat(\'  \',@class, \'  \'), \' lborder \')  and not(contains(concat(\' \',@class, \' \'), \' heading \')) or contains(concat(\' \',@class, \' \'), \' playerHeading \') or contains(concat(\' \',@class, \' \'), \' spacer \') ]'
  
  #get all the rows we're interested in, then look at the class of each one and decide what to do.  our delimiters are: class playerHeading, class spacer and class 
  
  recArray=doc.xpath(xpath_root).to_a
  
  f = File.open('D:\dev\nhl\temp.txt', "w")
  f.write(pp(recArray))
  f.close
  
  
  
  

  
end
parse_TOI_sheet('D:\dev\NHL\sheets\20132014\TH020022.HTM')