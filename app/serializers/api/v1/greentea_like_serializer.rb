module Api
  module V1
    class GreenteaLikeSerializer
      include JSONAPI::Serializer

      attributes :created_at

      attribute :greentea do |object, params|
        serialized = GreenteaSerializer.new(object.greentea, params: params).serializable_hash[:data]
        { id: serialized[:id].to_i }.merge(serialized[:attributes])
      end
    end
  end
end
