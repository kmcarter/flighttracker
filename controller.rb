require 'active_record'

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
	
	def new_flight flight_data
		new_flight = Flight.create(flight_data)
		#may be nil, if simulator was just started
		new_flight.previous_flight = @most_recent_flight
		direct_flight new_flight
		@most_recent_flight = new_flight
		new_flight
	end
	
	def direct_flight flight
		if flight.will_collide?
			new_speed = flight.find_maximum_speed
			if new_speed >= Flight::MIN_DESCENT_SPEED
				flight.adjust_speed new_speed
			else
				flight.divert
			end
		end
	end
	
	def update_flights
		Flight.where(status: [0, 1]).map do | flight | 
			flight.update_status
			flight
		end
	end
	
	def airborne_flights
		update_flights.select{ | flight | flight.descending? || flight.in_final_approach? }.sort_by { | flight | flight.status }
#		Flight.where(status: [0, 1]).order(created_at: :desc)
	end
	
	def landed_flights seconds_ago = 120
		update_flights
		Flight.where(status: 2).order(created_at: :desc).select{ | flight | Time.now <= flight.time_of_arrival + seconds_ago }
	end
	
	def self.create_tables
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
end

class Flight < ActiveRecord::Base
  ENTRY_ALTITUDE = 10000
	FLIGHT_DISTANCE = 64640
	FINAL_APPROACH_DISTANCE = 15021
	FINAL_APPROACH_COORDS = [ 44, -26 ]
	FINAL_APPROACH_ALTITUDE = 800
	LANDING_SPEED = 70
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
		update_status
		
		if descending?
			return descent_position distance
		elsif in_final_approach?
			return final_approach_position
		elsif landed?
			x = FINAL_APPROACH_COORDS.first
			y = FINAL_APPROACH_COORDS.last + FINAL_APPROACH_DISTANCE
		else #diverted position
			x = 16000
			y = 47000
		end

		return [x, y]
  end
	
	def current_altitude snapshot = Time.now
		if descending?
			(ENTRY_ALTITUDE - (snapshot - created_at) * 9200 / descent_duration).round(0)
		elsif in_final_approach?
			#Math.hypot(FINAL_APPROACH_ALTITUDE, FINAL_APPROACH_DISTANCE).round(0)
			#800 * time_remaining_in_final_approach / total_time_in_final_approach
			(-800 * (snapshot - created_at - descent_duration - final_approach_duration) / final_approach_duration).round(0)
		else
			0
		end
	end
	
	def flight_duration
		descent_duration + final_approach_duration
	end
	
	def descent_duration
		FLIGHT_DISTANCE / speed
	end
	
	#a method rather than a constant, because we theoretically may make it non-linear based on initial plane speed someday
	def final_approach_duration
		FINAL_APPROACH_DISTANCE / LANDING_SPEED
	end
	
	def time_of_arrival
		created_at + flight_duration
	end
	
	def will_collide? at_speed = speed
		return false if previous_flight.nil? || previous_flight.speed >= speed
		
		prev_flight_fa_time = previous_flight.created_at + previous_flight.descent_duration
		current_position = current_position_by_time(prev_flight_fa_time)
		distance = Math.hypot(current_position.first - FINAL_APPROACH_COORDS.first, current_position.last - FINAL_APPROACH_COORDS.last)
		distance < MIN_DISTANCE_BETWEEN_PLANES || prev_flight_fa_time > (created_at + descent_duration)
	end
  
  def adjust_speed new_speed
    if new_speed >= MIN_DESCENT_SPEED && new_speed <= MAX_DESCENT_SPEED
      update(speed: new_speed)
    else
			raise ArgumentError, "Plane speed must be between #{MIN_DESCENT_SPEED} and #{MAX_DESCENT_SPEED}."
    end
  end
	
	def find_maximum_speed
		beginning_speed = speed - 1
		#testing against MIN_DESCENT_SPEED-1 so that we know when we exit the loop unsuccessfully
		#(i.e. beginning_speed is < MIN_DESCENT_SPEED)
		while beginning_speed >= MIN_DESCENT_SPEED - 1
			break unless will_collide? beginning_speed
			beginning_speed -= 1
		end
		beginning_speed
	end
	
	def descending?
		status == "descent"
	end
	
	def in_final_approach?
		status == "final_approach"
	end
	
	def landed?
		#Time.now - created_at > descent_duration + (FINAL_APPROACH_DISTANCE / (speed + 70 / 2))
		status == "landed"
	end
  
  def divert
    update(status: :diverted)
  end
	
	def to_s
		"Flight ##{flight_number} (ID #{id}) flying at #{speed} m/s"
	end
	
	def to_h
		current_position = current_position_by_time
		{ 
			flight: flight_number, 
			x: current_position.first, 
			y: current_position.last, 
			speed: speed, 
			altitude: current_altitude, 
			status: status, 
			ingress: created_at.getlocal("-08:00"), 
			time_of_arrival: time_of_arrival.getlocal("-08:00") 
		}
	end
	
	#private
	def update_status
		#p Time.now.to_s + " vs. " + (created_at + descent_duration).to_s + " vs. " + (created_at + descent_duration + final_approach_duration).to_s
		if Time.now >= created_at + descent_duration + final_approach_duration
			update(status: :landed)
		elsif Time.now >= created_at + descent_duration
			update(status: :final_approach)
		end
	end
	
	def descent_position distance = distance_traveled
		x = ( -2.1e-12 * distance**3 ) -
				( 4.41e-6 * distance**2 ) +
				( 0.047 * distance ) + 16000

		y = ( 2.23e-14 * distance**4 ) -
				( 2e-9 * distance**3 ) +
				( 1.022e-4 * distance**2 ) -
				( 5 * distance ) + 47000

		return [x.round(0), y.round(0)]
	end
	
	def final_approach_position
		x = FINAL_APPROACH_COORDS.first
		y = FINAL_APPROACH_COORDS.last + LANDING_SPEED * (Time.now - created_at - descent_duration)

		return [x.round(0), y.round(0)]
	end
end