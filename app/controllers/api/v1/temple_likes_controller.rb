module Api
  module V1
    class TempleLikesController < BaseController
      before_action :require_authentication!

      def index
        scope = current_user.temple_likes.includes(temple: :areas).order(created_at: :desc)
        paginated = paginate(scope).load
        temple_ids = paginated.map(&:temple_id)
        like_counts = TempleLike.where(temple_id: temple_ids).group(:temple_id).count

        render_collection(
          paginated,
          serializer: TempleLikeSerializer,
          root: :temple_likes,
          serializer_params: { like_counts: like_counts }
        )
      end

      def create
        temple = Temple.find(params[:temple_id])
        like = current_user.temple_likes.find_or_create_by!(temple: temple)
        render_like(like)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        like = current_user.temple_likes.find_by!(temple: temple)
        render_like(like)
      end

      def destroy
        temple_id = params[:id].to_i
        like = current_user.temple_likes.find_by(temple_id: temple_id)
        return render_not_found unless like

        like.destroy!
        head :no_content
      end

      private

      def render_like(like)
        like_counts = { like.temple_id => TempleLike.where(temple_id: like.temple_id).count }
        render_resource(
          like,
          serializer: TempleLikeSerializer,
          root: :temple_like,
          serializer_params: { like_counts: like_counts }
        )
      end
    end
  end
end
