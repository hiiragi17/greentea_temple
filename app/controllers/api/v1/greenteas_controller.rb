module Api
  module V1
    class GreenteasController < BaseController
      def index
        scope = Greentea.ransack(params[:q]).result(distinct: true).order(:id)
        paginated = paginate(scope).load
        like_counts = GreenteaLike.where(greentea_id: paginated.map(&:id)).group(:greentea_id).count

        render_collection(
          paginated,
          serializer: GreenteaSerializer,
          serializer_params: { like_counts: like_counts }
        )
      end

      def show
        greentea = Greentea.includes(:genres).find(params[:id])
        nearby_temples = nearby_temples_for(greentea)

        render_resource(
          greentea,
          serializer: GreenteaDetailSerializer,
          serializer_params: {
            like_count: greentea.greentea_likes.size,
            nearby_temples: nearby_temples
          }
        )
      end

      private

      def nearby_temples_for(greentea)
        return [] unless greentea.latitude && greentea.longitude

        Temple
          .within(1.5, origin: [greentea.latitude, greentea.longitude])
          .by_distance(origin: [greentea.latitude, greentea.longitude])
      end
    end
  end
end
