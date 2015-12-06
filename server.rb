require "socket"
require "json"
load 'controller.rb'

class FlightServer
  CONTENT_TYPE_MAPPING = {
    'html' => 'text/html',
    'json' => 'application/json',
    'js' => 'application/javascript',
    'css' => 'text/css',
    'png' => 'image/png',
    'jpg' => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'txt' => 'text/plain'
  }
  DEFAULT_CONTENT_TYPE = 'application/json'
  WEB_ROOT = 'public'
  
  def initialize port = 80
    @port = port
    @controller = FlightController.new
  end
  
  def start
    @flight_server = TCPServer.open(@port)
    sockaddr = @flight_server.addr
    puts "Flight control server running on #{sockaddr.join(':')}"

    loop do
      Thread.start(@flight_server.accept) do | sock |
        path = sock.gets.split[1]
        p "Request for " + path
        sock.print serve_request(path)
        sock.close
      end
    end
  end
  
  def stop
    @flight_server.close
  end
  
  def serve_request rel_path
    #with thanks to https://practicingruby.com/articles/implementing-an-http-file-server
    rel_path = '/index.html' if rel_path == '/'
    path = WEB_ROOT + rel_path
    
    if rel_path.start_with? '/entry'
      message = JSON.generate(new_flight(rel_path).to_h)
      return headers(message.size) + message
    elsif rel_path.start_with? '/tracking_info'
      message = flight_statuses_to_json
      return headers(message.size) + message
    else
      if File.exist?(path) && !File.directory?(path)
        File.open(path, 'rb') do |file|
          return headers(file.size, content_type(path)) + file.read
        end
      else
        message = "File not found\n"
        # respond with a 404 error code to indicate the file does not exist
        return headers(message.size, CONTENT_TYPE_MAPPING['txt'], "404 Not Found") + message
      end
    end
  end
  
  def headers size, type = DEFAULT_CONTENT_TYPE, status_code = "200 OK"
    "HTTP/1.1 #{status_code}\r\n" +
    "Content-Type: #{type}\r\n" +
    "Content-Length: #{size}\r\n" +
    "Connection: close\r\n" +
    "\r\n"
  end
  
  def content_type(path)
    return DEFAULT_CONTENT_TYPE if path.nil?
    ext = File.extname(path).downcase.split(".").last
    CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
  end
  
  def new_flight path
    query_args = path.sub(/\/entry\?/, '').sub(/flight/, 'flight_number').split('&').map { | pair | pair.split('=') }.to_h
    query_args[:status] = :descent
    @controller.new_flight(query_args)
  end
  
  def flight_statuses_to_json
    all_flights = FlightController.landed_flights.concat(FlightController.airborne_flights)
    flights = all_flights.map { | flight | flight.to_h }
    JSON.generate({ aircrafts: flights })
  end
end

srv = FlightServer.new(3000)
srv.start