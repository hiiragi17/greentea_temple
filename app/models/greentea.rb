class Greentea < ApplicationRecord
    has_many :genres, through: :greentea_genres
    has_many :greentea_genres

    validates :name, presence: true
    validates :description, presence: true
    validates :longitude, presence: true
    validates :latitude, presence: true

    enum closed: { open: 0, close: 1 }

    geocoded_by :address
    after_validation :geocode, if: :address_changed?
end
