module Api
  module V1
    module Admin
      class TemplesController < BaseController
        def create
          temple = Temple.new(temple_params)
          if temple.save
            render_temple(temple, status: :created)
          else
            render_unprocessable(temple)
          end
        end

        def update
          temple = Temple.find(params[:id])
          if temple.update(temple_params)
            render_temple(temple)
          else
            render_unprocessable(temple)
          end
        end

        def destroy
          temple = Temple.find(params[:id])
          temple.destroy!
          head :no_content
        end

        private

        def temple_params
          params.require(:temple).permit(
            :name, :description, :address, :access, :phone_number,
            :business_hours, :holiday, :homepage, :img,
            :latitude, :longitude, area_ids: []
          )
        end

        # 作成・更新の戻りは読み取り系の詳細契約（TempleDetailSerializer）と同形にする。
        def render_temple(temple, status: :ok)
          render_resource(
            temple,
            serializer: TempleDetailSerializer,
            root: :temple,
            status: status,
            serializer_params: {
              likes_count: temple.temple_likes.size,
              nearby_greenteas: nearby_greenteas_for(temple),
              liked_by_current_user: current_user.temple_likes.exists?(temple_id: temple.id),
              current_user_id: current_user.id
            }
          )
        end

        def nearby_greenteas_for(temple)
          return [] unless temple.latitude && temple.longitude

          Greentea
            .within(1.5, origin: [temple.latitude, temple.longitude])
            .by_distance(origin: [temple.latitude, temple.longitude])
        end
      end
    end
  end
end
