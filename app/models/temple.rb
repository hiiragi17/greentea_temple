class Temple < ApplicationRecord
  has_many :temple_areas, dependent: :destroy
  has_many :areas, through: :temple_areas
  has_many :temple_likes, dependent: :destroy
  has_many :users, through: :temple_likes

  validates :name, presence: true
  validates :description, presence: true

  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  acts_as_mappable default_units: :kms,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :latitude,
                   lng_column_name: :longitude

  def get_distance(latitude, longitude)
    point = Geokit::LatLng.new(latitude, longitude)
    distance = distance_to(point) * 1000
    distance.round(-1)
  end
end
