class Area < ApplicationRecord
  has_many :temples, through: :temple_areas
  has_many :temple_areas, dependent: :destroy

  validates :name, presence: true
end
