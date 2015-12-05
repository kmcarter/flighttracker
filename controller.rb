require 'active_record'
require 'byebug'

class FlightController
	
	def initialize
		@most_recent_flight = nil
		ActiveRecord::Base.establish_connection(
			adapter: 'mysql2',
      database: 'flight_tracker',
			host: 'localhost',
			username: 'root',
			password: 'root'
		)
	end
	
	def create_tables
		ActiveRecord::Schema.define do
			create_table :flights do | t |
        t.string :flight_number, null: false
        t.integer :speed, null: false
        t.integer :status, null: false
        #t.column :status, :enum, limit: [ :descent, :final_approach, :landed, :diverted ], default: :descent
				t.timestamps null: false
			end
		end
	end
	
	def new_flight flight_data
		new_flight = Flight.create(flight_data)
		#may be nil, if simulator was just started
		new_flight.previous_flight = @most_recent_flight
		direct_flight new_flight
		@most_recent_flight = new_flight
	end
	
	def direct_flight flight
		if flight.will_collide?
			new_speed = flight.find_maximum_speed
			if !new_speed.is_nil? && new_speed >= Flight::MIN_DESCENT_SPEED
				flight.adjust_speed new_speed
			else
				flight.divert
			end
		end
	end
	
	def self.airborne_flights
		Flight.where(status: [0, 1]).map | flight | do
			flight.land if flight.landed?
		end
		Flight.where(status: [0, 1]).order(created_at: :desc)
	end
end

class Flight < ActiveRecord::Base
  ENTRY_ALTITUDE = 10000
	FLIGHT_DISTANCE = 64640
	FINAL_APPROACH_DISTANCE = 15021
	FINAL_APPROACH_COORDS = [ 44, -26 ]
  MIN_DESCENT_SPEED = 105
  MAX_DESCENT_SPEED = 128
	MIN_DISTANCE_BETWEEN_PLANES = 5200
	attr_accessor :previous_flight
	
  #From: https://github.com/ctran/annotate_models/issues/132#issuecomment-40807083
  enum status: [ :descent, :final_approach, :landed, :diverted ] unless instance_methods.include? :status
  validates :flight_number, presence: true
  validates :speed, presence: true
  validates :status, presence: true
	
	def distance_traveled snapshot = Time.now, at_speed = speed
		at_speed * (snapshot - created_at)
	end
	
	def current_position_by_time snapshot = Time.now
		#distance = velocity * time
		distance = distance_traveled snapshot
		current_position_by_distance distance
	end
  
	def current_position_by_distance distance = distance_traveled
		x = ( -2.1e-12 * distance**3 ) -
        ( 4.41e-6 * distance**2 ) +
        ( 0.047 * distance ) + 16000

		y = ( 2.23e-14 * distance**4 ) -
        ( 2e-9 * distance**3 ) +
        ( 1.022e-4 * distance**2 ) -
        ( 5 * distance ) + 47000

		return [x.round(0), y.round(0)]
  end
	
	def current_altitude snapshot = Time.now
		ENTRY_ALTITUDE - (snapshot - created_at) * 9200 / flight_duration
	end
	
	def flight_duration
		FLIGHT_DISTANCE / speed
	end
	
	def will_collide? at_speed = speed
		return false if previous_flight.nil?
		#p "Previous flight create time: " + previous_flight.created_at.to_s
		prev_flight_arrival_time = previous_flight.created_at + previous_flight.flight_duration
		#printf "Previous flight duration and speed: %s, %d\n", previous_flight.flight_duration.to_s, previous_flight.speed
		#p "Previous flight created at: " + previous_flight.created_at.to_s
		#p "Previous flight arrival time: " + prev_flight_arrival_time.to_s
		current_position = current_position_by_time(prev_flight_arrival_time)
		printf "Current position of current flight: %d, %d\n", current_position.first, current_position.last
		
		distance = Math.hypot(current_position.first - FINAL_APPROACH_COORDS.first, current_position.last - FINAL_APPROACH_COORDS.last)
		
		printf "Distance between flights: %d\n", distance
		distance < MIN_DISTANCE_BETWEEN_PLANES || prev_flight_arrival_time > (created_at + flight_duration)
	end
  
  def adjust_speed new_speed
    if new_speed >= MIN_DESCENT_SPEED && new_speed <= MAX_DESCENT_SPEED
      update(speed: new_speed)
    else
			raise ArgumentError, "Plane speed must be between #{MIN_DESCENT_SPEED} and #{MAX_DESCENT_SPEED}."
    end
  end
	
	def find_maximum_speed
		beginning_speed = speed
		while beginning_speed > MIN_DESCENT_SPEED
			if will_collide? beginning_speed
				beginning_speed -= 1
			else
				return beginning_speed
			end
		end
	end
	
	def landed?
		Time.now - created_at > flight_duration + (FINAL_APPROACH_DISTANCE / (speed + 70 / 2))
	end
	
	def land
		result = update(status: :landed)
	end
  
  def divert
    update(status: :diverted)
  end
	
	def to_s
		"Flight ##{flight_number} (ID #{id}) flying at #{speed} m/s"
	end
end