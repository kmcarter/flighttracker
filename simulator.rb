load 'controller.rb'

class FlightSimulator
  PLANE_FREQUENCY = 30..40
  ALPHABET = ('A'..'Z').to_a
  DIGITS = (0..9).to_a
  
  def initialize
    @controller = FlightController.new
  end
  
  def start
#     @colliding_flight3 = Flight.create(flight_number: 'GHI1234', speed: 115, status: :descent, created_at: Time.now)
#     @colliding_flight1 = Flight.create(flight_number: 'DEF5432', speed: 105, status: :descent, created_at: @colliding_flight2.created_at - 30.seconds)
#     @colliding_flight2 = Flight.create(flight_number: 'ABC9876', speed: 128, status: :descent, created_at: @colliding_flight3.created_at - 30.seconds)
    
    # generates flights every 30-40 seconds
    loop do
      p "Generating new flight at #{Time.now.to_s}"
      @controller.new_flight(generate_flight)
      sleep rand(PLANE_FREQUENCY)
    end
  end
  
  def generate_flight
    flight_num = ""
    6.times { |i| flight_num += (i < 4) ? ALPHABET.sample : DIGITS.sample.to_s }
    speed = rand(120..130)
    { flight_number: flight_num, speed: speed, status: :descent }
  end
end

#sim = FlightSimulator.new
#sim.start