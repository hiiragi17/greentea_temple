module Api
  module V1
    class NearbyTempleSerializer
      include JSONAPI::Serializer

      attributes :name, :latitude, :longitude

      attribute :distance_meters do |obj, params|
        if obj.respond_to?(:distance) && obj.distance
          (obj.distance.to_f * 1000).round
        else
          origin = params[:origin]
          if origin && origin[0] && origin[1]
            obj.get_distance(origin[0], origin[1])
          end
        end
      end
    end
  end
end
