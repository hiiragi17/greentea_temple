module Api
  module V1
    class NearbyGreenteaSerializer
      include JSONAPI::Serializer

      attributes :name, :latitude, :longitude

      attribute :distance_meters do |obj, params|
        if obj.respond_to?(:distance) && obj.distance
          (obj.distance.to_f * 1000).round
        else
          origin = params[:origin]
          if origin && origin[0] && origin[1] && obj.latitude && obj.longitude
            origin_point = Geokit::LatLng.new(origin[0], origin[1])
            target = Geokit::LatLng.new(obj.latitude, obj.longitude)
            (origin_point.distance_to(target, units: :kms) * 1000).round
          end
        end
      end
    end
  end
end
