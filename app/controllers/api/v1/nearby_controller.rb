module Api
  module V1
    class NearbyController < BaseController
      DEFAULT_RADIUS_KM = 1.5
      MAX_RADIUS_KM = 10
      MAX_RESULTS = 50

      def search
        lat = parse_float(params[:lat])
        lng = parse_float(params[:lng])
        radius = params[:radius].present? ? parse_float(params[:radius]) : DEFAULT_RADIUS_KM

        return render_bad_request unless valid_coordinates?(lat, lng) && valid_radius?(radius)

        origin = [lat, lng]

        render json: {
          greenteas: nearby_records(Greentea, origin, radius, NearbyGreenteaSerializer),
          temples: nearby_records(Temple, origin, radius, NearbyTempleSerializer)
        }
      end

      private

      def nearby_records(model, origin, radius, serializer)
        records = model
                  .within(radius, origin: origin)
                  .by_distance(origin: origin)
                  .limit(MAX_RESULTS)
                  .load
        serialized = serializer.new(records, params: { origin: origin }).serializable_hash
        flatten_serialized(serialized[:data])
      end

      def parse_float(value)
        return nil if value.blank?

        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      def valid_coordinates?(lat, lng)
        return false unless lat.is_a?(Numeric) && lng.is_a?(Numeric)
        return false unless lat.finite? && lng.finite?

        lat.abs <= 90 && lng.abs <= 180
      end

      def valid_radius?(radius)
        return false unless radius.is_a?(Numeric)
        return false unless radius.finite?

        radius.positive? && radius <= MAX_RADIUS_KM
      end
    end
  end
end
