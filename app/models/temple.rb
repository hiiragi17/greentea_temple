class Temple < ApplicationRecord
    has_many :areas, through: :temple_areas
    has_many :temple_areas

    validates :name, presence: true
    validates :description, presence: true

    geocoded_by :address
    after_validation :geocode, if: :address_changed?

    acts_as_mappable :default_units => :kms,
    :default_formula => :sphere,
    :distance_field_name => :distance,
    :lat_column_name => :lat,
    :lng_column_name => :lng
end
