#!/usr/bin/env ruby

require 'json'

GCLOUD = "/usr/bin/gcloud"

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
    puts "#{ipaddr}  #{instance['name']} #{instance['name']}.c.#{ARGV[0]}.internal"
  else
    puts "# [external-ip is none] #{instance['name']} #{instance['name']}.c.#{ARGV[0]}.internal"
  end
end

