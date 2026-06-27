class Greentea < ApplicationRecord
  # enum closed: { open: 0, close: 1 }

  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  has_many :greentea_genres, dependent: :destroy
  has_many :genres, through: :greentea_genres
  has_many :greentea_likes, dependent: :destroy
  has_many :users, through: :greentea_likes
  has_many :greenteacomments, dependent: :destroy
  # モデルルートに含まれる polymorphic な RouteSpot。店舗削除時に孤立行が残ると
  # RouteDetailSerializer が spottable=nil を参照して 500 になるため一緒に削除する。
  has_many :route_spots, as: :spottable, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true

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

  def self.ransackable_attributes(_auth_object = nil)
    %w[name description address access]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[genres greentea_genres]
  end
end
