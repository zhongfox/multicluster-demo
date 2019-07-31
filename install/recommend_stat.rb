#!/usr/bin/env ruby

require "json"
require 'net/http'
require 'optparse'


options = {}
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
  proxy_host = 'dev-proxy.oa.com'
  proxy_port = 8080
  uri = URI("http://#{ip}/api/mall")
  req = Net::HTTP::Get.new(uri)
  res = Net::HTTP::Proxy(proxy_host, proxy_port).start(uri.hostname, uri.port) {|http|
    http.request(req)
  }

  # res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  #   http.request(req)
  # }

  JSON.parse(res.body)
end

def analyze options
  stat = {
    v1: 0,
    v2: 0,
    error: 0
  }

  options[:count].times do |i|
    begin
    res = accessMall(options[:ip])
    rescue => e
      puts e
      stat[:error] = stat[:error] +1
      next
    end

    if res && res["recommend"] && res["recommend"]["products"]
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
  puts
end

TOTAL_REPLICAS = 14
(TOTAL_REPLICAS + 1).times do |i|
  unhealthy = i
  healthy = TOTAL_REPLICAS - i

  scaleUnhealthy = "kubectl --context guangzhou -nbase scale deploy/recommend-unhealthy --replicas=#{unhealthy}"
  scaleHealthy = "kubectl --context guangzhou -nbase scale deploy/recommend-v1 --replicas=#{healthy}"

  puts scaleUnhealthy
  puts scaleHealthy
  `#{scaleUnhealthy}`
  `#{scaleHealthy}`

  # wait for  all pods ready
  loop do
    sleep(3)
    wait = 'kubectl --context guangzhou -nbase get ep recommend -o jsonpath="{.subsets[0].addresses[*].ip}"'
    ips = `#{wait}`
    break if ips.split(' ').length == TOTAL_REPLICAS
  end

  analyze options
end

