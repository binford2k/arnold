#! /usr/bin/env ruby

# A quick 'n dirty example of a simple script to exercise Arnold's REST API

require 'net/https'
require 'rubygems'
require 'json'
require 'uri'

user   = 'admin'
pass   = 'admin'
server = 'localhost'

def provision()
  # Call VMware APIs to create a new machine, configure, and boot it.
  # Return its MAC address.
  return '00:0C:29:D1:03:A4'
end

macaddr = provision()

payload = {
  'macaddr'    => macaddr,
  'name'       => 'this.is.another.brand.new.system',
  'parameters' => {
                    'booga'   => 'wooga',
                    'fiddle'  => 'faddle',
                  },
  'classes'    => [ 'test', 'mysql', 'ntp' ],
}.to_json
 
uri = URI.parse("https://#{server}:9090/api/v1/create")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Post.new(uri.request_uri)
request.add_field('Content-Type', 'application/json')
request.basic_auth(user, pass)
request.body = payload
response = http.request(request)
puts "Response #{response.code} #{response.message}: #{response.body}"

