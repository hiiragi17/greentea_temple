class User < ApplicationRecord
  authenticates_with_sorcery!
  has_many :greentea_likes, dependent: :destroy
  has_many :greenteas, through: :greentea_likes, source: :greentea
  has_many :temple_likes, dependent: :destroy
  has_many :temples, through: :temple_likes, source: :temple
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications
  has_many :greenteacomments, dependent: :destroy
  has_many :templecomments, dependent: :destroy

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

  def temple_like?(temple)
    temples.include?(temple)
  end

  def temple_like(temple)
    temples << temple
  end

  def untemple_like(temple)
    temples.destroy(temple)
  end

  def own?(object)
    id == object.user_id
  end
end
