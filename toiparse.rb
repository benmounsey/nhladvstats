require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'
require 'pp'


def parse_toi_sheet(sheet)

#open the document as a nokogiri doc
doc = Nokogiri::HTML(open(sheet))

#find the players' team name [there is only one in the sheet]
shifttable = doc.css(#tablewidth>tbody)
teamname = 




















end