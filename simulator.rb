require './controller.rb'

class FlightSimulator
  PLANE_FREQUENCY = 30..40
  ALPHABET = ('AAA'..'ZZZ').to_a
  DIGITS = (0..9999).to_a
  
  def initialize
    @controller = FlightController.new
  end
  
  def start
    # generates flights every 30-40 seconds
    @thread = Thread.start do 
      loop do
        puts "Generating new flight at #{Time.now.to_s}"
        @controller.new_flight(generate_flight)
        sleep rand(PLANE_FREQUENCY)
      end
    end
    { status: @thread.status }
  end
  
  def stop
    @thread.exit
    puts "Simulator paused"
    { status: @thread.status }
  end
  
  def status
    @thread.status
  end
  
  def generate_flight
    flight_num = ALPHABET.sample + DIGITS.sample.to_s.ljust(4, "0")
    speed = rand(120..130)
    { flight_number: flight_num, speed: speed, status: :descent }
  end
end