class Greentea < ApplicationRecord
    geocoded_by :address
    after_validation :geocode, if: :address_changed?

    has_many :genres, through: :greentea_genres
    has_many :greentea_genres

    validates :name, presence: true
    validates :description, presence: true

    # enum closed: { open: 0, close: 1 }
end
