module Api
  module V1
    class TemplecommentsController < BaseController
      before_action :require_authentication!, except: [:index]

      def index
        temple = Temple.find(params[:temple_id])
        comments = temple.templecomments.includes(:user).order(created_at: :desc)

        render json: {
          data: comments.map { |c|
            {
              id: c.id,
              body: c.body,
              user: { id: c.user.id, name: c.user.name },
              own: current_user ? current_user.own?(c) : false,
              created_at: c.created_at.iso8601
            }
          }
        }
      end

      def create
        comment = current_user.templecomments.build(
          body: params[:body],
          temple_id: params[:temple_id]
        )

        if comment.save
          render json: {
            data: {
              id: comment.id,
              body: comment.body,
              user: { id: current_user.id, name: current_user.name },
              own: true,
              created_at: comment.created_at.iso8601
            }
          }, status: :created
        else
          render json: { error: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        comment = current_user.templecomments.find(params[:id])
        comment.destroy!
        render json: { message: '口コミを削除しました' }
      end
    end
  end
end
