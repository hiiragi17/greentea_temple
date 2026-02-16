module Api
  module V1
    class TempleLikesController < BaseController
      before_action :require_authentication!

      def index
        temples = current_user.temples.includes(:areas).order(created_at: :desc)
        render json: {
          data: temples.map { |t|
            {
              id: t.id,
              name: t.name,
              description: t.description,
              address: t.address,
              img: t.img,
              areas: t.areas.map { |area| { id: area.id, name: area.name } }
            }
          }
        }
      end

      def create
        temple = Temple.find(params[:temple_id])
        like = current_user.temple_likes.build(temple: temple)

        if like.save
          render json: { data: { id: like.id, temple_id: temple.id } }, status: :created
        else
          render json: { error: like.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        like = current_user.temple_likes.find(params[:id])
        like.destroy!
        render json: { message: 'いいねを取り消しました' }
      end
    end
  end
end
