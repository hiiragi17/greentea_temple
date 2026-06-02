module Api
  module V1
    class TempleSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

      attributes :name, :address, :access, :business_hours, :holiday,
                 :latitude, :longitude, :img

      attribute :like_count do |obj, params|
        params[:like_counts]&.fetch(obj.id, 0) || 0
      end

      attribute :liked_by_current_user do |_obj, _params|
        false
      end
    end
  end
end
