require 'nokogiri'
require 'open-uri'
require 'csv'

url = "https://www.lhexw.net/san/data-san3.html"
charset = nil

html = open(url, "r:CP932") do |f|
  charset = f.charset
  f.read
end

doc = Nokogiri::HTML.parse(html, nil, charset)
table = doc.xpath('//div[@class="ranking"]/table')

csv_text = CSV.generate{|csv|
  table.search(:tr).each do |tr|
    array = tr.search("td").map{|tag| tag.text}
    if !array[0].nil? and !array[0].include?('コピペご遠慮ください')
      csv << array
    end
  end
}

puts 'DS,名前,読み,武力,知力,政治,魅力,陸指,水指,合計,順位,偏差,軍師,将軍'
puts csv_text

