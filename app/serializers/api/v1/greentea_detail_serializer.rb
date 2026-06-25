module Api
  module V1
    class GreenteaDetailSerializer
      include JSONAPI::Serializer

      attributes :name, :description, :address, :access, :business_hours,
                 :holiday, :phone_number, :homepage, :latitude, :longitude, :img

      attribute :closed do |obj|
        obj.closed == 1
      end

      attribute :likes_count do |obj, params|
        params[:likes_count] || obj.greentea_likes.size
      end

      attribute :liked_by_current_user do |_obj, params|
        params[:liked_by_current_user] || false
      end

      attribute :genres do |obj|
        obj.genres.map { |g| { id: g.id, name: g.name } }
      end

      attribute :comments do |obj, params|
        obj.greenteacomments.sort_by(&:created_at).map do |comment|
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
