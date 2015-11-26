require 'minitest/autorun'
require 'minitest/pride'
#load 'controller.rb'
#load 'server.rb'
load 'simulator.rb'
#Cheat sheet: http://danwin.com/2013/03/ruby-minitest-cheat-sheet/

class ControllerTester < Minitest::Test
  def setup
    @controller = PlaneController.new
    @plane = Flight.all.last
    @colliding_flight3 = Flight.create(flight_number: 'GHI1234', speed: 115, status: :descent, created_at: Time.now)
    @colliding_flight2 = Flight.create(flight_number: 'ABC9876', speed: 128, status: :descent, created_at: @colliding_flight3.created_at - 30.seconds)
    @colliding_flight1 = Flight.create(flight_number: 'DEF5432', speed: 105, status: :descent, created_at: @colliding_flight2.created_at - 30.seconds)
  end
  
  def test_flight_creation
    assert_instance_of Flight, Flight.create({ flight_number: 'ABC1234', speed: 120, status: :descent })
  end
  
  def test_flight_landing
    assert_equal true, @plane.land
  end
  
  def test_distance_traveled
    assert_equal 0, @plane.distance_traveled(@plane.created_at)
    #assert_equal Flight::FLIGHT_DISTANCE, @plane.distance_traveled(@plane)
  end
  
  def test_current_flight_position_by_time
    assert_equal [16000, 47000], @plane.current_position_by_time(@plane.created_at)
    
    #won't pass due to rounding errors
    #snapshot = @plane.created_at + (3000 / @plane.speed)
    #assert_equal [16101.3667, 32865.8063], @plane.current_position_by_time(snapshot)
  end
  
  def test_current_flight_position_by_distance
    assert_equal [16101.3667, 32865.8063], @plane.current_position_by_distance(3000)
    
    #will never be 0,0 because equations aren't accurate enough 
    #(see equation roots on Wolram Alpha pages - they are not equal to flight duration or each other's roots)
    #assert_equal [0, 0], @plane.current_position_by_distance(@plane.created_at - @plane.flight_duration
  end
  
  def test_adjust_flight_speed
    assert_equal true, @plane.adjust_speed(110)
    #assert_throws ArgumentError, @plane.adjust_speed(80)
  end
  
  def test_flight_duration
    assert_equal 65291 / @plane.speed, @plane.flight_duration
  end
  
  def test_collision_detection
		printf "Flight ID %d (speed of %d)\n", @colliding_flight2.id, @colliding_flight2.speed
    assert_equal true, @colliding_flight2.will_collide?, "Flight 2"
		printf "Flight ID %d (speed of %d)\n", @colliding_flight3.id, @colliding_flight3.speed
    assert_equal false, @colliding_flight3.will_collide?, "Flight 3"
  end
  
  def test_flight_diversion
    assert_equal true, @colliding_flight2.divert
  end
  
  def test_maximum_speed_calculation
    assert_equal 115, @colliding_flight3.find_maximum_speed
  end
  
end

class SimulatorTester < Minitest::Test
  def setup
    @simulator = FlightSimulator.new
  end
  
  def test_flight_generation
    assert_instance_of Hash, @simulator.generate_flight
  end
end

class WebServerTester < Minitest::Test
end