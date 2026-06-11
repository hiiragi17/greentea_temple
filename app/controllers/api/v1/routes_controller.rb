module Api
  module V1
    class RoutesController < BaseController
      # 不正なスポット指定（存在しない spot / 未対応の spot_type / 不正な transport）を表す。
      class InvalidSpotError < StandardError; end

      before_action :require_authentication!

      def index
        scope = current_user.routes.order(created_at: :desc)
        paginated = paginate(scope).load
        spot_counts = RouteSpot.where(route_id: paginated.map(&:id)).group(:route_id).count

        render_collection(
          paginated,
          serializer: RouteSerializer,
          serializer_params: { spot_counts: spot_counts }
        )
      end

      def show
        route = current_user.routes.includes(route_spots: :spottable).find(params[:id])
        render_route_detail(route)
      end

      def create
        route = current_user.routes.new(name: route_params[:name], description: route_params[:description])

        ActiveRecord::Base.transaction do
          build_spots(route, spots_params)
          route.save!
        end

        render_route_detail(route, status: :created)
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable(e.record.errors.full_messages)
      rescue InvalidSpotError => e
        render_unprocessable([e.message])
      end

      def update
        route = current_user.routes.find(params[:id])

        ActiveRecord::Base.transaction do
          route.assign_attributes(name: route_params[:name], description: route_params[:description])
          route.route_spots.destroy_all
          build_spots(route, spots_params)
          route.save!
        end

        render_route_detail(route.reload)
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable(e.record.errors.full_messages)
      rescue InvalidSpotError => e
        render_unprocessable([e.message])
      end

      def destroy
        route = current_user.routes.find(params[:id])
        route.destroy!
        head :no_content
      end

      private

      def route_params
        params.require(:route).permit(:name, :description, spots: %i[spot_type spot_id transport])
      end

      def spots_params
        route_params[:spots] || []
      end

      # API の spots 配列（順序 = ルート順）から polymorphic な RouteSpot を組み立てる。
      def build_spots(route, spots)
        spots.each_with_index do |spot, index|
          spottable_type = RouteSpot.spottable_type_for(spot[:spot_type])
          raise InvalidSpotError, "invalid spot_type: #{spot[:spot_type]}" unless spottable_type

          record = spottable_type.constantize.find_by(id: spot[:spot_id])
          raise InvalidSpotError, "#{spot[:spot_type]} ##{spot[:spot_id]} not found" unless record

          route.route_spots.build(
            spottable: record,
            position: index + 1,
            transport: normalize_transport(spot[:transport])
          )
        end
      end

      def normalize_transport(value)
        return nil if value.blank?
        return value.to_s if RouteSpot.transports.key?(value.to_s)

        raise InvalidSpotError, "invalid transport: #{value}"
      end

      def render_route_detail(route, status: :ok)
        serialized = RouteDetailSerializer.new(route).serializable_hash
        render json: { data: flatten_one(serialized[:data]) }, status: status
      end

      def render_unprocessable(messages)
        render json: { error: 'Unprocessable Entity', details: messages }, status: :unprocessable_entity
      end
    end
  end
end
