class Temple < ApplicationRecord
    has_many :areas, through: :temple_areas
    has_many :temple_areas

    validates :name, presence: true
    validates :description, presence: true
    validates :longitude, presence: true
    validates :latitude, presence: true
end
