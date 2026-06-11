module Api
  module V1
    class RouteDetailSerializer
      include JSONAPI::Serializer

      attributes :name, :description

      attribute :created_at, &:created_at
      attribute :updated_at, &:updated_at

      attribute :spots do |obj|
        ordered = obj.route_spots.to_a
        ordered.each_with_index.map do |route_spot, index|
          next_spot = ordered[index + 1]
          RouteDetailSerializer.spot_payload(route_spot, next_spot)
        end
      end

      # ルート内の 1 スポットを表す要素を組み立てる。
      # distance_to_next_meters は次のスポットまでの距離（メートル・整数）。最後は nil。
      def self.spot_payload(route_spot, next_spot)
        spot = route_spot.spottable
        {
          position: route_spot.position,
          spot_type: route_spot.spot_type,
          transport: route_spot.transport,
          id: spot.id,
          name: spot.name,
          address: spot.address,
          access: spot.access,
          latitude: spot.latitude,
          longitude: spot.longitude,
          img: spot.img,
          distance_to_next_meters: distance_between(spot, next_spot&.spottable)
        }
      end

      def self.distance_between(spot, next_spot)
        return nil unless next_spot
        return nil unless spot.latitude && spot.longitude
        return nil unless next_spot.latitude && next_spot.longitude

        origin = Geokit::LatLng.new(spot.latitude, spot.longitude)
        target = Geokit::LatLng.new(next_spot.latitude, next_spot.longitude)
        (origin.distance_to(target, units: :kms) * 1000).round
      end
    end
  end
end
