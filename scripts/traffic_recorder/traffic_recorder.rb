### config
SERVER = "10.20.30.1"
SNMPCMD_IN = "/usr/bin/snmpwalk -v 2c -c casnmp #{SERVER} .1.3.6.1.2.1.31.1.1.1.6.7"
SNMPCMD_OUT = "/usr/bin/snmpwalk -v 2c -c casnmp #{SERVER} .1.3.6.1.2.1.31.1.1.1.10.7"
FILE_PATH = "./traffic-log/"
# 実行間隔(秒)
INTERVAL = 300

### method

# トラフィック量の差分を計算
def get_diff(now_in, now_out, last_in, last_out)
  diff_in = now_in.to_i - last_in.to_i
  diff_out = now_out.to_i - last_out.to_i
  return diff_in, diff_out
end

# トラフィック量(byte)と期間(秒)からMbpsに計算
def get_mbps(byte, interval)
  return byte.to_i * 8 / interval.to_i / (1024 * 1024)
end

### exec
date = Time.now

tra_in = `#{SNMPCMD_IN}`.split(/\s* \s*/)[3].chomp
tra_out = `#{SNMPCMD_OUT}`.split(/\s* \s*/)[3].chomp

file_name = FILE_PATH + "traffic-" + date.strftime("%Y%m%d").to_s + ".log"

# 存在チェックと追記
if File.exist?(file_name) then
  last_record = `/usr/bin/tail -n 1 #{file_name}`.split(",")
  diff_in, diff_out = get_diff(tra_in, tra_out, last_record[5], last_record[6])
else
  yesterday_file = FILE_PATH + "traffic-" + (date - 86400).strftime("%Y%m%d").to_s + ".log"
  last_record = `/usr/bin/tail -n 1 #{yesterday_file}`.split(",")
  if last_record.length == 0 then
    diff_in, diff_out = 0, 0
  else
    diff_in, diff_out = get_diff(tra_in, tra_out, last_record[5], last_record[6])
  end
end

# Mbpsへ換算
mbps_in = get_mbps(diff_in, INTERVAL)
mbps_out = get_mbps(diff_out, INTERVAL)

data = [
  date.strftime("%Y/%m/%d %H:%M:%S"),
  mbps_in,
  mbps_out,
  diff_in,
  diff_out,
  tra_in,
  tra_out
]

# ファイルに追記
File.open(file_name, "a"){|file|
  file.puts data.join(",")
}

