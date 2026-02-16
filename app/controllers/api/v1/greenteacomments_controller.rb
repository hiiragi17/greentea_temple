module Api
  module V1
    class GreenteacommentsController < BaseController
      before_action :require_authentication!, except: [:index]

      def index
        greentea = Greentea.find(params[:greentea_id])
        comments = greentea.greenteacomments.includes(:user).order(created_at: :desc)

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
        comment = current_user.greenteacomments.build(
          body: params[:body],
          greentea_id: params[:greentea_id]
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
        comment = current_user.greenteacomments.find(params[:id])
        comment.destroy!
        render json: { message: '口コミを削除しました' }
      end
    end
  end
end
