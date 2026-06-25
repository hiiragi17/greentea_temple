module Api
  module V1
    class TempleDetailSerializer
      include JSONAPI::Serializer

      attributes :name, :description, :address, :access, :business_hours,
                 :holiday, :phone_number, :homepage, :latitude, :longitude, :img

      attribute :likes_count do |obj, params|
        params[:likes_count] || obj.temple_likes.size
      end

      attribute :liked_by_current_user do |_obj, params|
        params[:liked_by_current_user] || false
      end

      attribute :areas do |obj|
        obj.areas.map { |a| { id: a.id, name: a.name } }
      end

      attribute :comments do |obj, params|
        obj.templecomments.map do |comment|
          {
            id: comment.id,
            body: comment.body,
            created_at: comment.created_at,
            owned_by_current_user: params[:current_user_id].present? &&
              comment.user_id == params[:current_user_id],
            user: { id: comment.user_id, name: comment.user&.name }
          }
        end
      end

      attribute :nearby_greenteas do |obj, params|
        nearby = params[:nearby_greenteas] || []
        serializer_params = {}
        serializer_params[:origin] = [obj.latitude, obj.longitude] if obj.latitude && obj.longitude
        serialized = NearbyGreenteaSerializer.new(nearby, params: serializer_params).serializable_hash[:data] || []
        serialized.map { |d| { id: d[:id].to_i, **d[:attributes] } }
      end
    end
  end
end
