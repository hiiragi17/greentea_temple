class Place < ApplicationRecord
    has_many :genres, through: :place_genres
    has_many :place_genres

    has_many :areas, through: :place_areas
    has_many :place_areas

    validates :name, presence: true
    validates :description, presence: true
    validates :longitude, presence: true
    validates :latitude, presence: true

    enum place_type: { green: 0, temple: 1 }

end
