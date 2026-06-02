module Api
  module V1
    class NearbyTempleSerializer
      include JSONAPI::Serializer

      set_id { |obj| obj.id }

      attributes :name, :latitude, :longitude

      attribute :distance_meters do |obj, params|
        origin = params[:origin]
        if origin
          obj.get_distance(origin[0], origin[1])
        elsif obj.respond_to?(:distance) && obj.distance
          (obj.distance.to_f * 1000).round
        end
      end
    end
  end
end
