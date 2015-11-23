require "socket"
flight_server = TCPServer.new('localhost', 80)
sockaddr = flight_server.addr
puts "Echo server running on #{sockaddr.join(':')}"

loop do
  Thread.start(flight_server.accept) do | sock |
    puts("#{sock} connected at #{Time.now}")
    loop do
      input = sock.gets
      sock.write(input)
      puts "User entered: #{input}"
    end
    puts("#{sock} disconnected at #{Time.now}")
    sock.close
  end
end