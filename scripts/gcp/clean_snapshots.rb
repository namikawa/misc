#!/usr/bin/env ruby

#########################################################################################
# このスクリプトは, 以下のルールでGCEのスナップショットをクリーニングする. 
#  - 対象ディスクのスナップショットが1世代しかない場合は, スナップショットを削除しない.
#  - 対象ディスクのスナップショットが複数ある場合は, 指定保持期間を経過したものを削除する.
#########################################################################################

require 'json'

# gcloud コマンドのパス
GCLOUD = "gcloud"
# スナップショットの最大保持期間(現時刻からの日数)
RETENTION_DAYS = 15
# ローテーション対象となるスナップショット名のサフィックス
SUFFIX = "--autobak"

### Def
def delete_suffix_str(str)
  s = String.new(str)
  s.slice!(SUFFIX)
  return s
end

### Exec
project_opt = ""
unless ARGV[0].nil? then
  project_opt = "--project=#{ARGV[0]}"
else
  STDERR.puts "[ERROR] invalid arguments. (ex. $ #{File.basename(__FILE__)} [Project Name])"
  exit!(1)
end

# スナップショット一覧の取得
list_res = JSON.parse(`#{GCLOUD} compute snapshots list #{project_opt} --format=json`)

if list_res.empty? then
  STDERR.puts "[ERROR] not get snapshots list."
  exit!(1)
end

source_disk_ids = [] 
list_res.each do |snapshot|
  # SUFFIX が名前に付与されている sourceDiskId を配列に挿入
  unless snapshot['name'].index(SUFFIX).nil? then
    source_disk_ids.push(snapshot['sourceDiskId'])
  end
end


source_disk_ids.sort.uniq.each do |disk_id|
  # 該当のディスクIDかつサフィックスの付くスナップショットの取得
  target = list_res.select { |snapshot| snapshot['sourceDiskId'] == disk_id and !snapshot['name'].index(SUFFIX).nil? }
  latest_time = "20000101-000000"
  latest_name = ""

  # 最新スナップショットの特定
  target.each do |disk|
    s = delete_suffix_str(disk['name'])

    if latest_time < s[-15, 15] then
      latest_time = s[-15, 15]
      latest_name = disk['name']
    end
  end

  # 保持期間外のスナップショットで最新以外を消去
  target.each do |disk|
    s = delete_suffix_str(disk['name'])
    threshold_day = Time.now - 24*60*60*RETENTION_DAYS

    if disk['name'] != latest_name and threshold_day.strftime("%Y%m%d-%H%M%S") > s[-15, 15] then
      del_res = `#{GCLOUD} -q compute snapshots delete #{disk['name']} #{project_opt}`
    end
  end
end

