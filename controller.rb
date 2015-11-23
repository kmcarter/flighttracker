require 'active_record'

class PlaneController
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
  
  def current_position distance
    x = ( 2.1e-12 * distance**3 ) -
        ( 4.41e-6 * distance**2 ) +
        ( 0.047 * distance ) + 16000

    y = ( 2.23e-14 * distance**4 ) -
        ( 2e-9 * distance**3 ) +
        ( 1.02e-4 * distance**2 ) -
        ( 5 * distance ) + 47000

    return [x, y]
  end
  
  def divert
    update(status: :diverted)
  end
end