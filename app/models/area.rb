class Area < ApplicationRecord
  has_many :temple_areas, dependent: :destroy
  has_many :temples, through: :temple_areas
  
  validates :name, presence: true
end
