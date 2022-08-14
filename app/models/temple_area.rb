class TempleArea < ApplicationRecord
  belongs_to :temple
  belongs_to :area

  validates :name, presence: true
end
