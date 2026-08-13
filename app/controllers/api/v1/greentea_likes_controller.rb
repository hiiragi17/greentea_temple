module Api
  module V1
    class GreenteaLikesController < BaseController
      before_action :require_authentication!

      def index
        scope = current_user.greentea_likes.includes(greentea: :genres).order(created_at: :desc)
        paginated = paginate(scope).load
        greentea_ids = paginated.map(&:greentea_id)
        like_counts = GreenteaLike.where(greentea_id: greentea_ids).group(:greentea_id).count

        render_collection(
          paginated,
          serializer: GreenteaLikeSerializer,
          root: :greentea_likes,
          serializer_params: { like_counts: like_counts }
        )
      end

      def create
        greentea = Greentea.find(params[:greentea_id])
        like = current_user.greentea_likes.find_or_create_by!(greentea: greentea)
        render_like(like)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        like = current_user.greentea_likes.find_by!(greentea: greentea)
        render_like(like)
      end

      def destroy
        greentea_id = params[:id].to_i
        like = current_user.greentea_likes.find_by(greentea_id: greentea_id)
        return render_not_found unless like

        like.destroy!
        head :no_content
      end

      private

      def render_like(like)
        like_counts = { like.greentea_id => GreenteaLike.where(greentea_id: like.greentea_id).count }
        render_resource(
          like,
          serializer: GreenteaLikeSerializer,
          root: :greentea_like,
          serializer_params: { like_counts: like_counts }
        )
      end
    end
  end
end
