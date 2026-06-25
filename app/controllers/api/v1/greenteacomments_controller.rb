module Api
  module V1
    class GreenteacommentsController < BaseController
      before_action :require_authentication!

      # 指定した抹茶店のコメント一覧（新しい順）。フロント契約に meta なし。
      def index
        greentea_id = params.require(:greentea_id)
        comments = Greenteacomment.includes(:user).where(greentea_id: greentea_id).order(created_at: :desc)

        render_full_collection(
          comments,
          serializer: GreenteacommentSerializer,
          root: :comments,
          serializer_params: { current_user_id: current_user.id }
        )
      end

      def create
        comment = current_user.greenteacomments.build(comment_params)
        if comment.save
          render_resource(
            comment,
            serializer: GreenteacommentSerializer,
            root: :comment,
            serializer_params: { current_user_id: current_user.id }
          )
        else
          render json: { error: 'Unprocessable Entity', details: comment.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        comment = Greenteacomment.find(params[:id])
        return render_forbidden unless comment.user_id == current_user.id

        comment.destroy!
        head :no_content
      end

      private

      def comment_params
        params.require(:greenteacomment).permit(:body, :greentea_id)
      end

      def render_forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
