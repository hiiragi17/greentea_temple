module Api
  module V1
    class GreenteasController < BaseController
      def index
        scope = Greentea.ransack(params[:q]).result(distinct: true).order(:id)
        paginated = paginate(scope).load
        ids = paginated.map(&:id)
        like_counts = GreenteaLike.where(greentea_id: ids).group(:greentea_id).count
        liked_ids = liked_ids_for(ids)

        render_collection(
          paginated,
          serializer: GreenteaSerializer,
          serializer_params: { like_counts: like_counts, liked_ids: liked_ids }
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
            nearby_temples: nearby_temples,
            liked_by_current_user: liked_by_current_user?(greentea.id)
          }
        )
      end

      private

      def liked_ids_for(ids)
        return [] unless current_user && ids.any?

        current_user.greentea_likes.where(greentea_id: ids).pluck(:greentea_id).to_set
      end

      def liked_by_current_user?(greentea_id)
        return false unless current_user

        current_user.greentea_likes.exists?(greentea_id: greentea_id)
      end

      def nearby_temples_for(greentea)
        return [] unless greentea.latitude && greentea.longitude

        Temple
          .within(1.5, origin: [greentea.latitude, greentea.longitude])
          .by_distance(origin: [greentea.latitude, greentea.longitude])
      end
    end
  end
end
