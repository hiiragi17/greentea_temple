module Api
  module V1
    class NearbyController < BaseController
      def search
        lat = params[:lat].to_f
        lng = params[:lng].to_f
        radius = (params[:radius] || 1.5).to_f

        unless lat.nonzero? && lng.nonzero?
          render json: { error: '緯度・経度が必要です' }, status: :bad_request
          return
        end

        origin = [lat, lng]

        greenteas = Greentea.within(radius, origin: origin)
                            .by_distance(origin: origin)
        temples = Temple.within(radius, origin: origin)
                        .by_distance(origin: origin)

        render json: {
          data: {
            greenteas: greenteas.map { |g|
              {
                id: g.id,
                name: g.name,
                address: g.address,
                img: g.img,
                latitude: g.latitude,
                longitude: g.longitude,
                distance_meters: distance_in_meters(lat, lng, g.latitude, g.longitude)
              }
            },
            temples: temples.map { |t|
              {
                id: t.id,
                name: t.name,
                address: t.address,
                img: t.img,
                latitude: t.latitude,
                longitude: t.longitude,
                distance_meters: distance_in_meters(lat, lng, t.latitude, t.longitude)
              }
            }
          }
        }
      end

      private

      def distance_in_meters(lat1, lng1, lat2, lng2)
        origin = Geokit::LatLng.new(lat1, lng1)
        destination = Geokit::LatLng.new(lat2, lng2)
        (origin.distance_to(destination, units: :kms) * 1000).round(-1)
      end
    end
  end
end
