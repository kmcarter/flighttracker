require 'active_record'

class PlaneController
  ENTRY_X = 16000
  ENTRY_Y = 47000
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
        ( 0.047 * distance ) + ENTRY_X

    y = ( 2.23e-14 * distance**4 ) -
        ( 2e-9 * distance**3 ) +
        ( 1.02e-4 * distance**2 ) -
        ( 5 * distance ) + ENTRY_Y

    return [x, y]
  end
	
	def current_altitude elapsed_time descent_duration
		#10000 – elapsed_time * 9200/descent_duration = 1000 – elapsed_time * 9200/505
	end
  
  def adjust_speed new_speed
    if (new_speed >= MIN_LANDING_SPEED && new_speed <= MAX_LANDING_SPEED)
      update(speed: new_speed)
    else
			raise ArgumentError, "Plane speed must be between #{MIN_LANDING_SPEED} and #{MAX_LANDING_SPEED}."
    end
  end
  
  def divert
    update(status: :diverted)
  end
end