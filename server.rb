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
    'txt' => 'text/plain'
  }
  DEFAULT_CONTENT_TYPE = 'text/plain'
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
        serve_request(path, sock)
        sock.close
      end
    end
  end
  
  def stop
    @flight_server.close
  end
  
  def serve_request rel_path, socket
    #with thanks to https://practicingruby.com/articles/implementing-an-http-file-server
    rel_path = '/index.html' if rel_path == '/'
    path = WEB_ROOT + rel_path
    
    if rel_path.start_with? '/entry'
      message = JSON.generate(new_flight(path))
      socket.print headers(message, CONTENT_TYPE_MAPPING['json'])
      socket.print message
    elsif rel_path.start_with? '/tracking_info'
      message = flight_statuses_to_json
      socket.print headers(message, CONTENT_TYPE_MAPPING['json'])
      socket.print message
    else
      if File.exist?(path) && !File.directory?(path)
        File.open(path, 'rb') do |file|
          socket.print headers(file, content_type(file))
          # write the contents of the file to the socket
          IO.copy_stream(file, socket)
        end
      else
        message = "File not found\n"
        #print message

        # respond with a 404 error code to indicate the file does not exist
        socket.print headers(message, CONTENT_TYPE_MAPPING['txt'], "404 Not Found")
        socket.print message
      end
    end
    nil
  end
  
  def headers content, content_type, status_code = "200 OK"
    "HTTP/1.1 #{status_code}\r\n" +
    "Content-Type: #{content_type}\r\n" +
    "Content-Length: #{content.size}\r\n" +
    "Connection: close\r\n" +
    "\r\n"
  end
  
  def content_type(path)
    return DEFAULT_CONTENT_TYPE if path.nil?
    ext = File.extname(path).split(".").last
    CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
  end
  
  def new_flight path
    query_args = path.sub(/\/entry\?/, '').sub(/flight/, 'flight_num').split('&').map { | pair | pair.split('=') }.to_h
    @controller.new_flight(query_args)
  end
  
  def flight_statuses_to_json
    all_flights = FlightController.landed_flights.concat(FlightController.airborne_flights)
    flights = all_flights.map { | flight | flight.to_h }
    JSON.generate({ aircrafts: flights })
  end
end

srv = FlightServer.new(3000)
#srv.start