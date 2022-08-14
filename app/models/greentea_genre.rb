class GreenteaGenre < ApplicationRecord
  belongs_to :greentea
  belongs_to :genre

  validates :name, presence: true
end
