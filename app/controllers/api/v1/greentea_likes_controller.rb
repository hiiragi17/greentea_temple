module Api
  module V1
    class GreenteaLikesController < BaseController
      before_action :require_authentication!

      # 自分のいいね一覧。各要素は { id(like), created_at, greentea: <フル spot> }。
      # ページネーションせず全件返す（フロント契約に meta なし）。
      def index
        likes = current_user.greentea_likes.includes(greentea: :genres).order(created_at: :desc)
        render_like_collection(likes)
      end

      def create
        greentea = Greentea.find(params[:greentea_id])
        like = current_user.greentea_likes.find_or_create_by!(greentea: greentea)
        render_like(like)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        render_like(current_user.greentea_likes.find_by!(greentea_id: greentea.id))
      end

      # :id は greentea_id として解決する（like レコードの id ではない）。
      def destroy
        like = current_user.greentea_likes.find_by(greentea_id: params[:id].to_i)
        return render_not_found unless like

        like.destroy!
        head :no_content
      end

      private

      def render_like_collection(likes)
        render_full_collection(
          likes,
          serializer: GreenteaLikeSerializer,
          root: :greentea_likes,
          serializer_params: { like_counts: like_counts_for(likes.map(&:greentea_id)) }
        )
      end

      def render_like(like)
        render_resource(
          like,
          serializer: GreenteaLikeSerializer,
          root: :greentea_like,
          serializer_params: { like_counts: like_counts_for([like.greentea_id]) }
        )
      end

      def like_counts_for(greentea_ids)
        GreenteaLike.where(greentea_id: greentea_ids).group(:greentea_id).count
      end
    end
  end
end
