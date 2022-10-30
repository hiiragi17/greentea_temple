class GreenteaLike < ApplicationRecord
  belongs_to :user
  belongs_to :greentea

  validates :user_id, uniqueness: { scope: :greentea_id }
end
