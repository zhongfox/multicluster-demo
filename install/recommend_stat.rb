#!/usr/bin/env ruby

require "json"
require 'net/http'
require 'optparse'

options = {}
stat = {
  v1: 0,
  v2: 0,
  error: 0
}


OptionParser.new do |opts|
  opts.banner = "Usage: recommend_stat.rb [options]"

  opts.on("--ip ip", String, "mall page ingress IP") do |v|
    options[:ip] = v
  end

  opts.on("--count count", Integer, "how many times to access mall ") do |v|
    options[:count] = v
  end

end.parse!
options[:ip] = options[:ip].to_s
options[:count] = options[:count].to_i
if options[:ip] ==  ""
  puts "ip can not be empty"
  exit 1
end
if options[:count] <=  0
  puts "count must greater than 0"
  exit 1
end

def accessMall ip
  uri = URI("http://#{ip}/api/mall")
  req = Net::HTTP::Get.new(uri)
  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)
  }

  JSON.parse(res.body)
end

options[:count].times do |i|
  res = accessMall(options[:ip])
  if res && res["recommend"] 
    if res["recommend"]["banner"]
      stat[:v2] = stat[:v2] +1
    else
      stat[:v1] = stat[:v1] +1
    end
  else
    stat[:error] = stat[:error] +1
  end
end
puts stat

