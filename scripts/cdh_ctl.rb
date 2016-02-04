#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'pit'

class Net::HTTP
  def initialize_new(address, port = nil)
    initialize_old(address, port)
    @open_timeout = 10
    @read_timeout = 10
  end
  alias :initialize_old :initialize
  alias :initialize :initialize_new
end

##### Check
if ARGV[0].nil? then
  STDERR.puts "[ERROR] Illegal Argument"
  exit!(1)
end

##### Exec
config = Pit.get('cdh-mgr')
uri = URI.parse("#{config['cluster_target']}commands/#{ARGV[0]}")

req = Net::HTTP::Post.new(uri.path)
req.basic_auth(config['username'], config['password'])

MAX_ATTEMPTS = 20
count = 0
res = {}

begin
  res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
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

if res.code == '200'
  STDOUT.puts res.body
else
  STDERR.puts "[ERROR] (#{res.code}) #{res.message}"
  exit!(1)
end

