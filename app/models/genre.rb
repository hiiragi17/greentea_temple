class Genre < ApplicationRecord
    has_many :places, through: :place_genres
    has_many :place_genres

    validates :name, presence: true
end
