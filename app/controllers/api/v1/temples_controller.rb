module Api
  module V1
    class TemplesController < BaseController
      def index
        search = Temple.ransack(params[:q])
        temples = search.result(distinct: true)
                       .includes(:areas)
                       .page(params[:page])
                       .per(params[:per] || 12)

        render json: {
          data: temples.map { |t| temple_summary(t) },
          meta: pagination_meta(temples)
        }
      end

      def show
        temple = Temple.find(params[:id])
        nearby_greenteas = if temple.latitude && temple.longitude
                             Greentea.within(1.5, origin: [temple.latitude, temple.longitude])
                                     .by_distance(origin: [temple.latitude, temple.longitude])
                           else
                             Greentea.none
                           end

        render json: {
          data: temple_detail(temple, nearby_greenteas)
        }
      end

      private

      def temple_summary(temple)
        {
          id: temple.id,
          name: temple.name,
          description: temple.description,
          address: temple.address,
          access: temple.access,
          img: temple.img,
          latitude: temple.latitude,
          longitude: temple.longitude,
          areas: temple.areas.map { |a| { id: a.id, name: a.name } },
          likes_count: temple.temple_likes.count,
          liked_by_current_user: current_user ? current_user.temple_like?(temple) : false
        }
      end

      def temple_detail(temple, nearby_greenteas)
        temple_summary(temple).merge(
          phone_number: temple.phone_number,
          business_hours: temple.business_hours,
          holiday: temple.holiday,
          homepage: temple.homepage,
          nearby_greenteas: nearby_greenteas.map { |g| greentea_nearby(g, temple) },
          comments: temple.templecomments.includes(:user).order(created_at: :desc).map { |c|
            {
              id: c.id,
              body: c.body,
              user: { id: c.user.id, name: c.user.name },
              created_at: c.created_at.iso8601
            }
          }
        )
      end

      def greentea_nearby(greentea, temple)
        {
          id: greentea.id,
          name: greentea.name,
          address: greentea.address,
          img: greentea.img,
          distance_meters: temple.get_distance(greentea.latitude, greentea.longitude)
        }
      end
    end
  end
end
