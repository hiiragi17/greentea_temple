module Api
  module V1
    class GreenteaSerializer
      include JSONAPI::Serializer

      attributes :name, :description, :address, :access, :phone_number,
                 :business_hours, :holiday, :homepage, :latitude, :longitude, :img

      attribute :closed do |obj|
        obj.closed == 1
      end

      attribute :genres do |obj|
        obj.genres.map { |g| { id: g.id, name: g.name } }
      end

      attribute :likes_count do |obj, params|
        params[:like_counts]&.fetch(obj.id, 0) || 0
      end
    end
  end
end
