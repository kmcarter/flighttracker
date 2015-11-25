require 'active_record'

class PlaneController
  ENTRY_ALTITUDE = 10000
  MIN_LANDING_SPEED = 105
  MAX_LANDING_SPEED = 128
	MIN_DISTANCE_BETWEEN_PLANES = 5200
	
	def initialize
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
end

class Flight < ActiveRecord::Base
	FLIGHT_DISTANCE = 65291
	FINAL_APPROACH_DISTANCE = 15021
	
  #From: https://github.com/ctran/annotate_models/issues/132#issuecomment-40807083
  enum status: [ :descent, :final_approach, :landed, :diverted ] unless instance_methods.include? :status
  validates :flight_number, presence: true
  validates :speed, presence: true
  validates :status, presence: true
  
  def current_position
		#distance = velocity * time
		distance = speed * (Time.now - created_at)
    x = ( 2.1e-12 * distance**3 ) -
        ( 4.41e-6 * distance**2 ) +
        ( 0.047 * distance ) + 16000

    y = ( 2.23e-14 * distance**4 ) -
        ( 2e-9 * distance**3 ) +
        ( 1.02e-4 * distance**2 ) -
        ( 5 * distance ) + 47000

    return [x, y]
  end
	
	def current_altitude descent_duration
		10000 – (Time.now - created_at) * 9200 / flight_duration
	end
	
	def flight_duration
		FLIGHT_DISTANCE / speed
	end
  
  def adjust_speed new_speed
    if (new_speed >= MIN_LANDING_SPEED && new_speed <= MAX_LANDING_SPEED)
      update(speed: new_speed)
    else
			raise ArgumentError, "Plane speed must be between #{MIN_LANDING_SPEED} and #{MAX_LANDING_SPEED}."
    end
  end
	
	def landed?
		Time.now - created_at > flight_duration + (FINAL_APPROACH_DISTANCE / (speed + 70 / 2))
	end
  
  def divert
    update(status: :diverted)
  end
end