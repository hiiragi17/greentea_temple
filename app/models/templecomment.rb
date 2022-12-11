class Templecomment < ApplicationRecord
  belongs_to :user
  belongs_to :temple

  validates :body, presence: true, length: { maximum: 65_535 }
end
