class Genre < ApplicationRecord
    has_many :greenteas, through: :greentea_genres
    has_many :greentea_genres, dependent: :destroy, foreign_key: 'genre_id'


    validates :name, presence: true

end
