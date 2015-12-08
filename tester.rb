require 'minitest/autorun'
require 'minitest/pride'
load 'server.rb'
load 'simulator.rb'
#Cheat sheet: http://danwin.com/2013/03/ruby-minitest-cheat-sheet/

class ControllerTester < Minitest::Test
  def setup
    @controller = FlightController.new
		if ActiveRecord::Base.connection.tables.size == 0
			FlightController.create_tables
		end
		
		if Flight.all.length == 0
			@colliding_flight3 = Flight.create({ flight_number: 'ABC1234', speed: 115, status: :descent })
			@colliding_flight2 = Flight.create({ flight_number: 'ABC1235', speed: 128, status: :descent })
			@colliding_flight1 = Flight.create({ flight_number: 'ABC1236', speed: 105, status: :descent })
			@plane = Flight.create({ flight_number: 'ABC1234', speed: 128, status: :descent })
			@landed_flight = Flight.create({ flight_number: 'ABC1237', speed: 128, status: :landed })
		else
			@colliding_flight3 = Flight.find(1) #115 m/s
			@colliding_flight2 = Flight.find(2) #128 m/s
			@colliding_flight1 = Flight.find(3) #105 m/s
			@plane = Flight.all.last
			@landed_flight = Flight.where(status: 2).limit(1).first
		end
		
		@colliding_flight3.previous_flight = @colliding_flight2
		@colliding_flight2.previous_flight = @colliding_flight1
  end
  
  def test_flight_creation
    assert_instance_of Flight, Flight.create({ flight_number: 'ABC1237', speed: 128, status: :descent })
  end
  
  def test_distance_traveled
    assert_equal 0, @plane.distance_traveled(@plane.created_at)
		assert_equal Flight::FLIGHT_DISTANCE, @plane.distance_traveled(@plane.created_at + 505), @plane.to_s
  end
  
	def test_current_flight_position_by_distance
		#descent
		
		#final_approach
		#assert_equal [Flight::FINAL_APPROACH_COORDS.first, Flight::FINAL_APPROACH_COORDS.last + Flight::FINAL_APPROACH_DISTANCE], @plane.current_position_by_distance(@plane.created_at + @plane.flight_duration), @plane.to_s
		
		#landed
		assert_equal [Flight::FINAL_APPROACH_COORDS.first, Flight::FINAL_APPROACH_COORDS.last + Flight::FINAL_APPROACH_DISTANCE], @landed_flight.current_position_by_distance, @landed_flight.to_s
	end
  
  def test_current_flight_position_by_time
		#descent
		assert_equal [16000, 47000], @plane.current_position_by_time(@plane.created_at), @plane.to_s
		assert_equal Flight::FINAL_APPROACH_COORDS, @plane.current_position_by_time(@plane.created_at + @plane.descent_duration), @plane.to_s #why does this always return [80, -495]?
		snapshot = @plane.created_at + (3200 / @plane.speed)
    assert_equal [16105, 31983], @plane.current_position_by_time(snapshot), @plane.to_s
		
		#final approach
		assert_equal [Flight::FINAL_APPROACH_COORDS.first, Flight::FINAL_APPROACH_COORDS.last + Flight::FINAL_APPROACH_DISTANCE], @plane.current_position_by_time(@plane.time_of_arrival), @plane.to_s
		
  end
  
	def test_descent_position_by_distance
		assert_equal [16105, 31983], @plane.descent_position(3200), @plane.to_s
    
    #will never be 0,0 because equations aren't accurate enough
    assert_equal Flight::FINAL_APPROACH_COORDS, @plane.descent_position(Flight::FLIGHT_DISTANCE), @plane.to_s
  end
  
  def test_descent_duration
    assert_equal Flight::FLIGHT_DISTANCE / @plane.speed, @plane.descent_duration
  end
  
  def test_collision_detection
		assert_equal true, @colliding_flight2.will_collide?, "#2: " + @colliding_flight2.to_s
    assert_equal false, @colliding_flight3.will_collide?, "#3: " + @colliding_flight3.to_s
  end
  
  def test_flight_diversion
    assert_equal true, @colliding_flight2.divert
  end
  
  def test_maximum_speed_calculation
    assert_equal 114, @colliding_flight3.find_maximum_speed
		assert_equal 104, @colliding_flight1.find_maximum_speed
  end
  
  def test_adjust_flight_speed
    assert_equal true, @plane.adjust_speed(128)
		assert_raises (ArgumentError) { @plane.adjust_speed(80) }
  end
  
	def test_airborne_flights
		assert_instance_of Array, @controller.airborne_flights
	end
  
	def test_landed_flights
		assert_instance_of Flight::ActiveRecord_Relation, @controller.landed_flights
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

class ServerTester < Minitest::Test
	def setup
		@server = FlightServer.new
	end
	
	def test_serve_request
		assert_instance_of String, @server.serve_request('/')
	end
	
	def test_content_type
		assert_equal 'application/json', @server.content_type('/test.json')
		assert_equal 'application/javascript', @server.content_type('/js/global.js')
		assert_equal 'text/css', @server.content_type('/css/tracker.css')
		assert_equal FlightServer::DEFAULT_CONTENT_TYPE, @server.content_type('/')
		assert_equal 'text/plain', @server.content_type('/test.txt')
		assert_equal 'image/jpeg', @server.content_type('/img/flight.jpg')
		assert_equal 'image/jpeg', @server.content_type('/img/flight.JPEG')
		assert_equal 'image/png', @server.content_type('/img/flight.png')
	end
	
	def test_flight_statuses_to_json
		assert_instance_of String, @server.flight_statuses_to_json
	end
	
	def test_new_flight
		assert_instance_of Flight, @server.new_flight('/entry?flight=XYZ4932&speed=105')
	end
end