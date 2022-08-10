class Genre < ApplicationRecord
    validates :name, presence: true
end
