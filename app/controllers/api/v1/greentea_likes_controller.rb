module Api
  module V1
    class GreenteaLikesController < BaseController
      before_action :require_authentication!

      def index
        scope = current_user.greenteas.order('greentea_likes.created_at DESC')
        paginated = paginate(scope).load
        ids = paginated.map(&:id)
        like_counts = GreenteaLike.where(greentea_id: ids).group(:greentea_id).count

        render_collection(
          paginated,
          serializer: GreenteaSerializer,
          serializer_params: { like_counts: like_counts, liked_ids: ids.to_set }
        )
      end

      def create
        greentea = Greentea.find(params[:greentea_id])
        current_user.greentea_likes.find_or_create_by!(greentea: greentea)
        render_like_state(greentea.id, liked: true)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        render_like_state(greentea.id, liked: true)
      end

      def destroy
        greentea_id = params[:id].to_i
        like = current_user.greentea_likes.find_by(greentea_id: greentea_id)
        return render_not_found unless like

        like.destroy!
        render_like_state(greentea_id, liked: false)
      end

      private

      def render_like_state(greentea_id, liked:)
        render json: {
          data: {
            greentea_id: greentea_id,
            liked: liked,
            like_count: GreenteaLike.where(greentea_id: greentea_id).count
          }
        }, status: :ok
      end
    end
  end
end
