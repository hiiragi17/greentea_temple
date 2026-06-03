module Api
  module V1
    class GreenteaDetailSerializer
      include JSONAPI::Serializer

      attributes :name, :description, :address, :access, :business_hours,
                 :holiday, :phone_number, :homepage, :latitude, :longitude, :img

      attribute :like_count do |obj, params|
        params[:like_count] || obj.greentea_likes.size
      end

      attribute :liked_by_current_user do |_obj, _params|
        false
      end

      attribute :genres do |obj|
        obj.genres.map { |g| { id: g.id, name: g.name } }
      end

      attribute :nearby_temples do |obj, params|
        nearby = params[:nearby_temples] || []
        serializer_params = {}
        serializer_params[:origin] = [obj.latitude, obj.longitude] if obj.latitude && obj.longitude
        serialized = NearbyTempleSerializer.new(nearby, params: serializer_params).serializable_hash[:data] || []
        serialized.map { |d| { id: d[:id].to_i, **d[:attributes] } }
      end
    end
  end
end
