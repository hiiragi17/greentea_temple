class Greentea < ApplicationRecord
    validates :name, presence: true
    validates :description, presence: true
    validates :longitude, presence: true
    validates :latitude, presence: true

    enum place_type: { open: 0, close: 1 }
end
