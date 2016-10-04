#!/usr/bin/env ruby

require 'json'

GCLOUD = "/usr/bin/gcloud"
SUFFIX = ".localdomain"

project_opt = ""
unless ARGV[0].nil? then
  project_opt = "--project=#{ARGV[0]}"
end

result = JSON.parse(`#{GCLOUD} compute instances list #{project_opt} --format=json`)

result.each do |instance|
  ipaddr = ""
  instance['networkInterfaces'].each do |ni|
    ni['accessConfigs'].each do |config|
      if (config['name'] == "External NAT") || (config['name'] == "external-nat") then
        ipaddr = config['natIP']
      end
    end
  end

  unless ipaddr.nil? then
    puts "dns static a #{instance['name']}#{SUFFIX} #{ipaddr} ttl=30"
  end
end

