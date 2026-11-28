module Api
  module V1
    class RouteDetailSerializer
      include JSONAPI::Serializer

      attributes :name, :description

      attribute :created_at, &:created_at
      attribute :updated_at, &:updated_at

      attribute :spots do |obj|
        ordered = RouteDetailSerializer.ordered_spots(obj)
        ordered.each_with_index.map do |route_spot, index|
          next_spot = ordered[index + 1]
          RouteDetailSerializer.spot_payload(route_spot, next_spot)
        end
      end

      # ルート全体の直線距離合計（メートル・整数）。
      attribute :total_distance_meters do |obj|
        RouteDetailSerializer.total_distance_meters(RouteDetailSerializer.ordered_spots(obj))
      end

      # route_spots を position 順で取得する。association scope（order(:position)）でも
      # 担保されるが、DB ロード順に依存しないよう明示的に並べ替える（controller と統一）。
      def self.ordered_spots(route)
        route.route_spots.to_a.sort_by(&:position)
      end

      # ルート内の 1 スポットを表す要素を組み立てる。
      # 移動手段・経路距離・所要時間は扱わない（行き方はフロントから Google マップに任せる）。
      # - distance_to_next_meters: 次スポットまでの直線距離（メートル・整数）。最後は nil。
      def self.spot_payload(route_spot, next_spot)
        spot = route_spot.spottable
        {
          position: route_spot.position,
          spot_type: route_spot.spot_type,
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

      def self.total_distance_meters(ordered)
        return 0 if ordered.size < 2

        ordered.each_cons(2).sum { |from, to| distance_between(from.spottable, to.spottable) || 0 }
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
