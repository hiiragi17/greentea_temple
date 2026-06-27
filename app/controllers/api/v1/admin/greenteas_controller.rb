module Api
  module V1
    module Admin
      class GreenteasController < BaseController
        def create
          greentea = Greentea.new(greentea_params)
          if greentea.save
            render_greentea(greentea, status: :created)
          else
            render_unprocessable(greentea)
          end
        end

        def update
          greentea = Greentea.find(params[:id])
          if greentea.update(greentea_params)
            render_greentea(greentea)
          else
            render_unprocessable(greentea)
          end
        end

        def destroy
          greentea = Greentea.find(params[:id])
          greentea.destroy!
          head :no_content
        end

        private

        def greentea_params
          permitted = params.require(:greentea).permit(
            :name, :description, :address, :access, :phone_number,
            :business_hours, :holiday, :homepage, :closed, :img,
            :latitude, :longitude, genre_ids: []
          )
          permitted[:closed] = normalize_closed(permitted[:closed]) if permitted.key?(:closed)
          permitted
        end

        # 作成・更新の戻りは読み取り系の詳細契約（GreenteaDetailSerializer）と同形にする。
        def render_greentea(greentea, status: :ok)
          render_resource(
            greentea,
            serializer: GreenteaDetailSerializer,
            root: :greentea,
            status: status,
            serializer_params: {
              likes_count: greentea.greentea_likes.size,
              nearby_temples: nearby_temples_for(greentea),
              liked_by_current_user: current_user.greentea_likes.exists?(greentea_id: greentea.id),
              current_user_id: current_user.id
            }
          )
        end

        def nearby_temples_for(greentea)
          return [] unless greentea.latitude && greentea.longitude

          Temple
            .within(1.5, origin: [greentea.latitude, greentea.longitude])
            .by_distance(origin: [greentea.latitude, greentea.longitude])
        end
      end
    end
  end
end
