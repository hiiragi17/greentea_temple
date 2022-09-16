class Genre < ApplicationRecord
  has_many :greenteas, through: :greentea_genres
  has_many :greentea_genres, dependent: :destroy

  validates :name, presence: true
end
