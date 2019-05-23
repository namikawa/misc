require 'csv'

res = false

CSV.foreach('./sangokushi3_comp.csv', headers: false) do |row|
  if row[7] == ARGV[0]
    puts "名前: #{row[6]}"
    puts "武力: #{row[0]}"
    puts "知力: #{row[1]}"
    puts "政治: #{row[2]}"
    puts "魅力: #{row[3]}"
    puts "陸指: #{row[4]}"
    puts "水指: #{row[5]}"
    puts "-----"
    puts "raw : #{row[6]},#{row[0]},#{row[1]},#{row[2]},#{row[3]},#{row[4]},#{row[5]}"

    res = true
    break
  end
end

unless res
  puts 'not found.'
end

