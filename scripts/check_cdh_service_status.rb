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

def get_uri_and_req(target_uri, config)
  uri = URI.parse(target_uri)
  req = Net::HTTP::Get.new(uri.path)
  req.basic_auth(config['username'], config['password'])
  return uri, req
end

##### Exec
config = Pit.get('cdh-mgr')

# status check
status_uri, status_req = get_uri_and_req(config['service_target'], config)

res = Net::HTTP.new(status_uri.host, status_uri.port).start {|http| http.request(status_req) }
if res.code == '200'
  result = JSON.parse(res.body)
  STDOUT.puts result['entityStatus']
else
  STDERR.puts "[ERROR] (#{res.code}) #{res.message}"
  exit!(1)
end

