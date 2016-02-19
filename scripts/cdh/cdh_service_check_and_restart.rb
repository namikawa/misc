#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'pit'
require 'json'

class Net::HTTP
  def initialize_new(address, port = nil)
    initialize_old(address, port)
    @open_timeout = 10
    @read_timeout = 10
  end
  alias :initialize_old :initialize
  alias :initialize :initialize_new
end

def get_uri_and_get_req(target_uri, config)
  uri = URI.parse(target_uri)
  req = Net::HTTP::Get.new(uri.path)
  req.basic_auth(config['username'], config['password'])
  return uri, req
end

def get_uri_and_post_req(target_uri, config)
  uri = URI.parse(target_uri)
  req = Net::HTTP::Post.new(uri.path)
  req.basic_auth(config['username'], config['password'])
  return uri, req
end

def req_http(uri, req)
  res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }

  if res.code == '200'
    STDOUT.puts res.body
  else
    STDERR.puts "[ERROR] (#{res.code}) #{res.message}"
    exit!(1)
  end
end

##### Exec
config = Pit.get('cdh-mgr')

# status check
status_uri, status_req = get_uri_and_get_req(config['service_target'], config)
stop_uri, stop_req = get_uri_and_post_req("#{config['service_target']}commands/stop", config)
start_uri, start_req = get_uri_and_post_req("#{config['service_target']}commands/start", config)

MAX_ATTEMPTS = 10
count = 0
good_health = true

begin
  5.times do
    res = Net::HTTP.new(status_uri.host, status_uri.port).start {|http| http.request(status_req) }

    if res.code == '200'
      result = JSON.parse(res.body)
      puts "Status: #{result['entityStatus']}"

      if result['entityStatus'] != "GOOD_HEALTH"
        good_health = false
        puts "sleep..."
        sleep(10)
      else
        good_health = true
        break
      end
    end
  end
rescue => e
  count += 1
  if count <= MAX_ATTEMPTS
    sleep(10)
    STDOUT.puts "retry wait 10s ... (#{count})"
    retry
  else
    STDERR.puts "[ERROR] #{e}"
    exit!(1)
  end
end

# service stop/start
if !good_health
  req_http(stop_uri, stop_req)
  sleep(10)
  req_http(start_uri, start_req)
end

