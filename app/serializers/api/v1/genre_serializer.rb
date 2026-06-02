module Api
  module V1
    class GenreSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

      attributes :name
    end
  end
end
