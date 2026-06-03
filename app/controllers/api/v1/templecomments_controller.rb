module Api
  module V1
    class TemplecommentsController < BaseController
      before_action :require_authentication!

      def index
        temple_id = params.require(:temple_id)
        scope = Templecomment.includes(:user).where(temple_id: temple_id).order(created_at: :desc)
        paginated = paginate(scope).load

        render_collection(
          paginated,
          serializer: TemplecommentSerializer,
          serializer_params: { current_user_id: current_user.id }
        )
      end

      def create
        comment = current_user.templecomments.build(comment_params)
        if comment.save
          render_resource(
            comment,
            serializer: TemplecommentSerializer,
            serializer_params: { current_user_id: current_user.id }
          )
        else
          render json: { error: 'Unprocessable Entity', details: comment.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        comment = Templecomment.find(params[:id])
        return render_forbidden unless comment.user_id == current_user.id

        comment.destroy!
        head :no_content
      end

      private

      def comment_params
        params.require(:templecomment).permit(:body, :temple_id)
      end

      def render_forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
