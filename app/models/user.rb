class User < ApplicationRecord
  authenticates_with_sorcery!
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications
  has_many :greentea_likes, dependent: :destroy
  has_many :greenteas, through: :greentea_likes, source: :greentea

  validates :name, presence: true

  enum role: { general: 0, admin: 1 }

  def greentea_like?(greentea)
    greenteas.include?(greentea)
  end

  def greentea_like(greentea)
   greenteas << greentea
  end
  
  def ungreentea_like(greentea)
    greenteas.destroy(greentea)
  end
end
