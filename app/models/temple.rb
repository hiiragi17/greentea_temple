class Temple < ApplicationRecord
    has_many :areas, through: :temple_areas
    has_many :temple_areas

    validates :name, presence: true
    validates :description, presence: true

    geocoded_by :address
    after_validation :geocode, if: :address_changed?
end
