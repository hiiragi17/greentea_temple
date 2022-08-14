class Genre < ApplicationRecord
    has_many :greenteas, through: :greentea_genres
    has_many :greentea_genres

    validates :name, presence: true

end
