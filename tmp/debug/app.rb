require 'sinatra'
require 'net/http'
$stdout.sync = true

service = ENV['SERVICE']
destinations = ENV['DESTINATIONS']

def start_service service
  puts "starting service #{service}"

  set :bind, '0.0.0.0'
  set :port, 7000
  get "/#{service}" do
    content_type :text
    puts "receiving call from #{request.ip}"
    "response from #{service} service"
  end
end

def call_service service
  puts "calling service #{service}"
  uri = URI("http://#{service}:7000/#{service}")
  req = Net::HTTP::Get.new(uri)
  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)
  }
  puts res.body
end

def call_destinations destinations
  services = destinations.split ","
  loop do 
    services.each do |service|
      begin
      call_service service
      rescue => e
        puts "call service #{service} error: #{e}"
      end
    end
    sleep 1
  end
end

if service
  start_service service
elsif destinations
  call_destinations destinations
else
  puts "miss env service or destinations, exiting"
  exit 1
end


