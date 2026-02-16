module Api
  module V1
    class GreenteaLikesController < BaseController
      before_action :require_authentication!

      def index
        greenteas = current_user.greenteas.includes(:genres).order(created_at: :desc)
        render json: {
          data: greenteas.map { |g|
            {
              id: g.id,
              name: g.name,
              description: g.description,
              address: g.address,
              img: g.img,
              genres: g.genres.map { |genre| { id: genre.id, name: genre.name } }
            }
          }
        }
      end

      def create
        greentea = Greentea.find(params[:greentea_id])
        like = current_user.greentea_likes.build(greentea: greentea)

        if like.save
          render json: { data: { id: like.id, greentea_id: greentea.id } }, status: :created
        else
          render json: { error: like.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        like = current_user.greentea_likes.find(params[:id])
        like.destroy!
        render json: { message: 'いいねを取り消しました' }
      end
    end
  end
end
