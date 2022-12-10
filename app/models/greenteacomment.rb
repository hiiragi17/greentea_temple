class Greenteacomment < ApplicationRecord
  belongs_to :user
  belongs_to :greentea

  validates :body, presence: true, length: { maximum: 65_535 }
end
