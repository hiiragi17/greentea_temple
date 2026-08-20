class Greenteacomment < ApplicationRecord
  include BannedWordValidatable

  belongs_to :user
  belongs_to :greentea

  validates :body, presence: true, length: { maximum: 65_535 }
end
