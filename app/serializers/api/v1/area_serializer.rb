module Api
  module V1
    class AreaSerializer
      include JSONAPI::Serializer

      attributes :name
    end
  end
end
