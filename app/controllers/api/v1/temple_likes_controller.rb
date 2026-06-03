module Api
  module V1
    class TempleLikesController < BaseController
      before_action :require_authentication!

      def index
        scope = current_user.temples.order('temple_likes.created_at DESC')
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

        render json: {
          data: {
            temple_id: temple.id,
            liked: true,
            like_count: temple.temple_likes.count
          }
        }, status: :ok
      rescue ActiveRecord::RecordNotUnique
        render json: {
          data: {
            temple_id: temple.id,
            liked: true,
            like_count: temple.temple_likes.count
          }
        }, status: :ok
      end

      def destroy
        temple_id = params[:id].to_i
        like = current_user.temple_likes.find_by(temple_id: temple_id)
        return render_not_found unless like

        like.destroy!
        render json: {
          data: {
            temple_id: temple_id,
            liked: false,
            like_count: TempleLike.where(temple_id: temple_id).count
          }
        }, status: :ok
      end
    end
  end
end
