require 'minitest/autorun'
require 'minitest/pride'
load 'controller.rb'
#load 'server.rb'
load 'simulator.rb'
#Cheat sheet: http://danwin.com/2013/03/ruby-minitest-cheat-sheet/

class ControllerTester < Minitest::Test
  def setup
    @controller = PlaneController.new
    @plane = Flight.all.last
  end
  
  def test_flight_creation
    assert_instance_of Flight, Flight.create, { flight_number: 'ABC1234', speed: 120, status: :descent }
  end
  
  def test_flight_diversion
    assert_equal true, @plane.divert
  end
  
#   def test_current_flight_position
#     assert_equal current_position
#   end
  
end

class SimulatorTester < Minitest::Test
  def setup
    @simulator = FlightSimulator.new
  end
  
  def test_flight_generation
    assert_instance_of Flight, @simulator.generate_flight
  end
end

class WebServerTester < Minitest::Test
end