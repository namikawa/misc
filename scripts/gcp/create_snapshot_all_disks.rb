#!/usr/bin/env ruby

require 'json'

GCLOUD = "gcloud"
ZONE = "asia-east1-a"

project_opt = ""
unless ARGV[0].nil? then
  project_opt = "--project=#{ARGV[0]}"
else
  STDERR.puts "[ERROR] invalid arguments. (ex. $ #{File.basename(__FILE__)} [Project Name])"
  exit!(1)
end

list_res = JSON.parse(`#{GCLOUD} compute disks list #{project_opt} --format=json`)

if list_res.empty? then
  STDERR.puts "[ERROR] not get disks list."
  exit!(1)
end

disks = ""
snapshots = ""
time = Time.now.strftime("%Y%m%d-%H%M%S")

list_res.each do |disk|
  if disks.empty? and snapshots.empty? then
    disks = disk['name']
    snapshots = disk['name'] + "-" + time
  else
    disks += " " + disk['name']
    snapshots += "," + disk['name'] + "-" + time + "--autobak"
  end
end

if disks.empty? or snapshots.empty? then
  STDERR.puts "[ERROR] no target disks for snapshot."
  exit!(1)
end

puts "--- Target Disks   : " + disks
puts "--- Snapshot Names : " + snapshots

snap_res = `#{GCLOUD} compute disks snapshot #{disks} --snapshot-names #{snapshots} --zone #{ZONE} #{project_opt}`
puts snap_res

