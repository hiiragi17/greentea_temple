module Api
  module V1
    class GenreSerializer
      include JSONAPI::Serializer

      attributes :name
    end
  end
end
