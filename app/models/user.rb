class User < ApplicationRecord
  authenticates_with_sorcery!
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: lambda {
                                                          new_record? || changes[:crypted_password]
                                                        }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  enum role: { general: 0, admin: 1 }
end
