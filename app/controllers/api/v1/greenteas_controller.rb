module Api
  module V1
    class GreenteasController < BaseController
      def index
        scope = Greentea.includes(:genres).ransack(params[:q]).result(distinct: true).order(:id)
        paginated = paginate(scope).load
        ids = paginated.map(&:id)
        like_counts = GreenteaLike.where(greentea_id: ids).group(:greentea_id).count

        render_collection(
          paginated,
          serializer: GreenteaSerializer,
          root: :greenteas,
          serializer_params: { like_counts: like_counts }
        )
      end

      def show
        greentea = Greentea.includes(:genres, greenteacomments: :user).find(params[:id])
        nearby_temples = nearby_temples_for(greentea)

        render_resource(
          greentea,
          serializer: GreenteaDetailSerializer,
          root: :greentea,
          serializer_params: {
            likes_count: greentea.greentea_likes.size,
            nearby_temples: nearby_temples,
            liked_by_current_user: liked_by_current_user?(greentea.id),
            current_user_id: current_user&.id
          }
        )
      end

      private

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
