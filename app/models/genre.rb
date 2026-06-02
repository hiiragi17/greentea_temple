class Genre < ApplicationRecord
  has_many :greentea_genres, dependent: :destroy
  has_many :greenteas, through: :greentea_genres

  validates :name, presence: true
end
