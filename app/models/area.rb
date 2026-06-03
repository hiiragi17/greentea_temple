class Area < ApplicationRecord
  has_many :temple_areas, dependent: :destroy
  has_many :temples, through: :temple_areas

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
