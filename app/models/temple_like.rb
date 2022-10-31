class TempleLike < ApplicationRecord
  belongs_to :user
  belongs_to :temple

  validates :user_id, uniqueness: { scope: :temple_id }
end
