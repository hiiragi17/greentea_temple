module Api
  module V1
    class TempleLikesController < BaseController
      before_action :require_authentication!

      # 自分のいいね一覧。各要素は { id(like), created_at, temple: <フル spot> }。
      # ページネーションせず全件返す（フロント契約に meta なし）。
      def index
        likes = current_user.temple_likes.includes(temple: :areas).order(created_at: :desc)
        render_like_collection(likes)
      end

      def create
        temple = Temple.find(params[:temple_id])
        like = current_user.temple_likes.find_or_create_by!(temple: temple)
        render_like(like)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        render_like(current_user.temple_likes.find_by!(temple_id: temple.id))
      end

      # :id は temple_id として解決する（like レコードの id ではない）。
      def destroy
        like = current_user.temple_likes.find_by(temple_id: params[:id].to_i)
        return render_not_found unless like

        like.destroy!
        head :no_content
      end

      private

      def render_like_collection(likes)
        render_full_collection(
          likes,
          serializer: TempleLikeSerializer,
          root: :temple_likes,
          serializer_params: { like_counts: like_counts_for(likes.map(&:temple_id)) }
        )
      end

      def render_like(like)
        render_resource(
          like,
          serializer: TempleLikeSerializer,
          root: :temple_like,
          serializer_params: { like_counts: like_counts_for([like.temple_id]) }
        )
      end

      def like_counts_for(temple_ids)
        TempleLike.where(temple_id: temple_ids).group(:temple_id).count
      end
    end
  end
end
