require 'csv'

CSV.foreach(ARGV[0], headers: true) do |row|
  puts "#{row['武力']},#{row['知力']},#{row['政治']},#{row['魅力']},#{row['陸指']},#{row['水指']},\"#{row['名前']}\""
end

