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

      # ルート全体の経路距離合計（メートル・整数）。
      # 各 leg は経路距離（leg_distance_meters）優先、無ければ直線距離でフォールバック。
      attribute :total_distance_meters do |obj|
        RouteDetailSerializer.total_distance_meters(RouteDetailSerializer.ordered_spots(obj))
      end

      # ルート全体の所要時間合計（秒・整数）。算出済みの leg が 1 つも無ければ nil。
      attribute :total_duration_seconds do |obj|
        RouteDetailSerializer.total_duration_seconds(RouteDetailSerializer.ordered_spots(obj))
      end

      # route_spots を position 順で取得する。association scope（order(:position)）でも
      # 担保されるが、DB ロード順に依存しないよう明示的に並べ替える（controller と統一）。
      def self.ordered_spots(route)
        route.route_spots.to_a.sort_by(&:position)
      end

      # ルート内の 1 スポットを表す要素を組み立てる。
      # - distance_to_next_meters: 次スポットまでの直線距離（メートル・整数）。最後は nil。
      # - route_distance_to_next_meters: 次スポットまでの経路距離（Directions API）。未算出は nil。
      # - duration_to_next_seconds: 次スポットまでの所要時間（秒）。未算出は nil。
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
          distance_to_next_meters: distance_between(spot, next_spot&.spottable),
          route_distance_to_next_meters: next_spot ? route_spot.leg_distance_meters : nil,
          duration_to_next_seconds: next_spot ? route_spot.leg_duration_seconds : nil
        }
      end

      def self.total_distance_meters(ordered)
        return 0 if ordered.size < 2

        ordered.each_cons(2).sum do |from, to|
          from.leg_distance_meters || distance_between(from.spottable, to.spottable) || 0
        end
      end

      # 所要時間には直線距離のようなフォールバックが無いため、算出済みの leg のみを
      # 合算する（一部 leg のみ算出済みなら部分合計）。1 つも無ければ nil。
      # ＝ total_distance_meters（常に整数）とは非対称だが意図的な契約。
      def self.total_duration_seconds(ordered)
        durations = ordered.each_cons(2).map { |from, _to| from.leg_duration_seconds }.compact
        return nil if durations.empty?

        durations.sum
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
