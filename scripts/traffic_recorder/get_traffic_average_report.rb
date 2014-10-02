# traffic_recorder.rb で出力したログファイルの平均算出に使います

### config
LOG_PATH = "./traffic"
LOG_FILE = [
  "traffic-20130810.log",
  "traffic-20130811.log",
  "traffic-20130812.log",
  "traffic-20130813.log",
  "traffic-20130814.log",
  "traffic-20130815.log",
  "traffic-20130816.log"
]
OUTPUT_FILE = "./traffic_average.log"
#min
INTERVAL = 5


### exec
# ファイル存在・行数チェック
LOG_FILE.each do |file|
  result = File.exist?("#{LOG_PATH}/#{file}")
  if !result
    STDERR.puts "#{LOG_PATH}/#{file}: file not exist."
    exit!
  end

  result = File.readlines("#{LOG_PATH}/#{file}").size
  if result != 1440 / INTERVAL
    STDERR.puts "#{LOG_PATH}/#{file}: line count (#{result}) is invalid."
    exit!
  end
end

# 各ファイル読み込み
average = {}

# 各ファイルの各行の足し算
LOG_FILE.each do |file|
  f = File.open("#{LOG_PATH}/#{file}", "r")
  f.each_line {|line|
    array = line.split(",")
    array[0].slice!(0..10)
    array[0].slice!(array[0].rindex(":")..array[0].length)

    if average.key?(array[0])
      # keyが存在する場合(2回目以降)
      value = average[array[0]]
      value[0] = value[0].to_i + array[1].to_i
      value[1] = value[1].to_i + array[2].to_i
    else
      # keyが存在しない場合(1回目)
      value = [array[1].to_i, array[2].to_i]
    end
    average.store(array[0], value)
  }
end

# ログファイルの日数による割り算
File.open(OUTPUT_FILE, "w"){|file|
  average.to_a.each do |value|
    file.puts "#{value[0]},#{sprintf('%.2f', value[1][0].to_f / LOG_FILE.length.to_f)},#{sprintf('%.2f', value[1][1].to_f / LOG_FILE.length.to_f)}"
  end
}

