#!/usr/bin/env ruby2.0

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

##### Exec
config = Pit.get('cdh-mgr')
uri = URI.parse(config['target'])

req = Net::HTTP::Get.new(uri.path)
req.basic_auth(config['username'], config['password'])
res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }

if res.code == '200'
  result = JSON.parse(res.body)
  STDOUT.puts result['entityStatus']
else
  STDERR.puts "[ERROR] (#{res.code}) #{res.message}"
  exit!(1)
end

