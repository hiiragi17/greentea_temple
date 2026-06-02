module Api
  module V1
    class GreenteaDetailSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

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
        origin = [obj.latitude, obj.longitude]
        serialized = NearbyTempleSerializer.new(nearby, params: { origin: origin }).serializable_hash[:data]
        serialized.map { |d| { id: d[:id].to_i, **d[:attributes] } }
      end
    end
  end
end
