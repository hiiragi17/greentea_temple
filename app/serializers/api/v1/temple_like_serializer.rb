module Api
  module V1
    class TempleLikeSerializer
      include JSONAPI::Serializer

      attributes :created_at

      attribute :temple do |object, params|
        serialized = TempleSerializer.new(object.temple, params: params).serializable_hash[:data]
        { id: serialized[:id].to_i }.merge(serialized[:attributes])
      end
    end
  end
end
