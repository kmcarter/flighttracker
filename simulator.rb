load 'controller.rb'

class FlightSimulator
  PLANE_FREQUENCY = 30..40
  
  def initialize
    @controller = PlaneController.new
  end
  
  def start
    # generates flights ever 30-40 seconds
  end
  
  def generate_flight
    alphabet = ('A'..'Z').to_a
    digits = (0..9).to_a
    flight_num = ""
    6.times { |i| flight_num += (i < 4) ? alphabet.sample : digits.sample.to_s }
    speed = rand(120..130)
    { flight_number: flight_num, speed: speed, status: :descent }
  end
end

sim = FlightSimulator.new
sim.start