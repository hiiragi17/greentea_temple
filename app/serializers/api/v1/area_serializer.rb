module Api
  module V1
    class AreaSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

      attributes :name
    end
  end
end
