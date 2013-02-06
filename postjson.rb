#! /usr/bin/env ruby

require 'net/https'
require 'rubygems'
require 'json'
require 'uri'

user = 'admin'
pass = 'admin'

payload = {
  'macaddr'    => '00:0C:29:E1:78:A1',
  'parameters' => {
                    'booga'   => 'wooga',
                    'fiddle'  => 'faddle',
                  },
  'classes'    => [ 
                    'apache',
                    'ntp::client',
                  ],
}.to_json
 
uri = URI.parse("https://localhost:9090/api/v1/create")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Post.new(uri.request_uri)
request.add_field('Content-Type', 'application/json')
request.basic_auth(user, pass)
request.body = payload
response = http.request(request)
puts "Response #{response.code} #{response.message}: #{response.body}"

