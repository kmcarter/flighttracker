require "socket"
require "json"
require 'byebug'
load 'controller.rb'

class FlightServer
  
  def initialize host = 'localhost', port = 80
    @host = host
    @port = port
    @controller = FlightController.new
  end
  
  def start
    @flight_server = TCPServer.new(@host, @port)
    sockaddr = @flight_server.addr
    puts "Echo server running on #{sockaddr.join(':')}"

    loop do
      Thread.start(@flight_server.accept) do | sock |
        puts "#{sock} connected at #{Time.now}"
        sock.write(current_flights_to_json)
        puts "#{sock} disconnected at #{Time.now}"
        sock.close
      end
    end
  end
  
  def stop
    @flight_server.close
  end
  
  def current_flights_to_json
    flights = @controller.current_flights
    JSON.generate(flights)
  end
end

#srv = FlightServer.new('localhost', '1024')
#srv.start