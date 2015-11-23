load 'controller.rb'

class FlightSimulator
  ENTRY_X = 16000
  ENTRY_Y = 47000
  ENTRY_MIN_ALTITUDE = 8000
  ENTRY_MAX_ALTITUDE = 12000
  
  def initialize
    @controller = PlaneController.new
  end
  
  def generate_flight
    alphabet = ('A'..'Z').to_a
    digits = (0..9).to_a
    flight_num = ""
    6.times { |i| flight_num += (i < 4) ? alphabet.sample : digits.sample.to_s }
    speed = rand(120..130)
    Flight.create(flight_number: flight_num, speed: speed, status: :descent)
  end
end