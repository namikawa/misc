require 'csv'

CSV.foreach(ARGV[0]) do |row|
  print(row.join("\t") + "\n")
end

