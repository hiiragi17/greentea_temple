class Area < ApplicationRecord
    has_many :places, through: :place_areas
    has_many :place_areas

    validates :name, presence: true
end
