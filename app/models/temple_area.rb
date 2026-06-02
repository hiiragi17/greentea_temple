class TempleArea < ApplicationRecord
  belongs_to :temple
  belongs_to :area

  def self.ransackable_attributes(_auth_object = nil)
    %w[id temple_id area_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[temple area]
  end
end
