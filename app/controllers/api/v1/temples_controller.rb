module Api
  module V1
    class TemplesController < BaseController
      def index
        scope = Temple.ransack(params[:q]).result(distinct: true).order(:id)
        paginated = paginate(scope).load
        like_counts = TempleLike.where(temple_id: paginated.map(&:id)).group(:temple_id).count

        render_collection(
          paginated,
          serializer: TempleSerializer,
          serializer_params: { like_counts: like_counts }
        )
      end

      def show
        temple = Temple.includes(:areas).find(params[:id])
        nearby_greenteas = nearby_greenteas_for(temple)

        render_resource(
          temple,
          serializer: TempleDetailSerializer,
          serializer_params: {
            like_count: temple.temple_likes.size,
            nearby_greenteas: nearby_greenteas
          }
        )
      end

      private

      def nearby_greenteas_for(temple)
        return [] unless temple.latitude && temple.longitude

        Greentea
          .within(1.5, origin: [temple.latitude, temple.longitude])
          .by_distance(origin: [temple.latitude, temple.longitude])
      end
    end
  end
end
