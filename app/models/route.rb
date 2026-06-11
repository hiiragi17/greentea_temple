class Route < ApplicationRecord
  belongs_to :user
  has_many :route_spots, -> { order(:position) }, dependent: :destroy, inverse_of: :route

  accepts_nested_attributes_for :route_spots, allow_destroy: true

  validates :name, presence: true
  validates :route_spots, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name description]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[route_spots]
  end
end
