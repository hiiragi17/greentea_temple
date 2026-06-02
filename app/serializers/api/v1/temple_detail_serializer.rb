module Api
  module V1
    class TempleDetailSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

      attributes :name, :description, :address, :access, :business_hours,
                 :holiday, :phone_number, :homepage, :latitude, :longitude, :img

      attribute :like_count do |obj, params|
        params[:like_count] || obj.temple_likes.size
      end

      attribute :liked_by_current_user do |_obj, _params|
        false
      end

      attribute :areas do |obj|
        obj.areas.map { |a| { id: a.id, name: a.name } }
      end

      attribute :nearby_greenteas do |obj, params|
        nearby = params[:nearby_greenteas] || []
        origin = [obj.latitude, obj.longitude]
        serialized = NearbyGreenteaSerializer.new(nearby, params: { origin: origin }).serializable_hash[:data]
        serialized.map { |d| { id: d[:id].to_i, **d[:attributes] } }
      end
    end
  end
end
