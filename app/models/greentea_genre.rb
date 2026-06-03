class GreenteaGenre < ApplicationRecord
  belongs_to :greentea
  belongs_to :genre

  def self.ransackable_attributes(_auth_object = nil)
    %w[id greentea_id genre_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[greentea genre]
  end
end
