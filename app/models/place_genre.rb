class PlaceGenre < ApplicationRecord
  belongs_to :place
  belongs_to :genre
end
