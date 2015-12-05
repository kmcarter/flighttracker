require "socket"
require "json"
require 'byebug'
load 'controller.rb'

class FlightServer
  CONTENT_TYPE_MAPPING = {
    'html' => 'text/html',
    'json' => 'application/json',
    'js' => 'application/javascript',
    'css' => 'text/css',
    'png' => 'image/png',
    'jpg' => 'image/jpeg'
  }
  DEFAULT_CONTENT_TYPE = 'application/octet-stream'
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
    #path_segments = rel_path.split('/')
    rel_path = '/index.html' if rel_path == '/'
    path = WEB_ROOT + rel_path
    
    if rel_path.start_with? '/entry'
      "Creating flight from params"
    elsif rel_path.start_with? '/tracking_info'
      current_flights_to_json
    else
      if File.exist?(path) && !File.directory?(path)
        File.open(path, 'rb') do |file|
          socket.print "HTTP/1.1 200 OK\r\n" +
                       "Content-Type: #{content_type(file)}\r\n" +
                       "Content-Length: #{file.size}\r\n" +
                       "Connection: close\r\n"

          socket.print "\r\n"

          # write the contents of the file to the socket
          IO.copy_stream(file, socket)
        end
      else
        message = "File not found\n"
        print message

        # respond with a 404 error code to indicate the file does not exist
        socket.print "HTTP/1.1 404 Not Found\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{message.size}\r\n" +
                     "Connection: close\r\n"

        socket.print "\r\n"

        socket.print message
      end
    end
  end
  
  def content_type(path)
    ext = File.extname(path).split(".").last
    CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
  end
  
  def current_flights_to_json
    flights = FlightController.airborne_flights.map do | flight |
      { id: flight.id, flight_num: flight.flight_num, speed: flight.speed, altitude: flight.current_altitude }
    end
    JSON.generate(flights)
  end
end

srv = FlightServer.new(3000)
srv.start