module Api
  module V1
    class TempleLikesController < BaseController
      before_action :require_authentication!

      def index
        scope = current_user.temples.includes(:areas).order('temple_likes.created_at DESC')
        paginated = paginate(scope).load
        ids = paginated.map(&:id)
        like_counts = TempleLike.where(temple_id: ids).group(:temple_id).count

        render_collection(
          paginated,
          serializer: TempleSerializer,
          serializer_params: { like_counts: like_counts, liked_ids: ids.to_set }
        )
      end

      def create
        temple = Temple.find(params[:temple_id])
        current_user.temple_likes.find_or_create_by!(temple: temple)
        render_like_state(temple.id, liked: true)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        render_like_state(temple.id, liked: true)
      end

      def destroy
        temple_id = params[:id].to_i
        like = current_user.temple_likes.find_by(temple_id: temple_id)
        return render_not_found unless like

        like.destroy!
        render_like_state(temple_id, liked: false)
      end

      private

      def render_like_state(temple_id, liked:)
        render json: {
          data: {
            temple_id: temple_id,
            liked: liked,
            like_count: TempleLike.where(temple_id: temple_id).count
          }
        }, status: :ok
      end
    end
  end
end
