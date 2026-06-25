module Api
  module V1
    class TempleSerializer
      include JSONAPI::Serializer

      attributes :name, :description, :address, :access, :phone_number,
                 :business_hours, :holiday, :homepage, :latitude, :longitude, :img

      attribute :areas do |obj|
        obj.areas.map { |a| { id: a.id, name: a.name } }
      end

      attribute :likes_count do |obj, params|
        params[:like_counts]&.fetch(obj.id, 0) || 0
      end
    end
  end
end
