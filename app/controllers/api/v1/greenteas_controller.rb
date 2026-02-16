module Api
  module V1
    class GreenteasController < BaseController
      def index
        search = Greentea.ransack(params[:q])
        greenteas = search.result(distinct: true)
                         .includes(:genres)
                         .page(params[:page])
                         .per(params[:per] || 12)

        render json: {
          data: greenteas.map { |g| greentea_summary(g) },
          meta: pagination_meta(greenteas)
        }
      end

      def show
        greentea = Greentea.find(params[:id])
        nearby_temples = if greentea.latitude && greentea.longitude
                           Temple.within(1.5, origin: [greentea.latitude, greentea.longitude])
                                 .by_distance(origin: [greentea.latitude, greentea.longitude])
                         else
                           Temple.none
                         end

        render json: {
          data: greentea_detail(greentea, nearby_temples)
        }
      end

      private

      def greentea_summary(greentea)
        {
          id: greentea.id,
          name: greentea.name,
          description: greentea.description,
          address: greentea.address,
          access: greentea.access,
          img: greentea.img,
          latitude: greentea.latitude,
          longitude: greentea.longitude,
          genres: greentea.genres.map { |g| { id: g.id, name: g.name } },
          likes_count: greentea.greentea_likes.count,
          liked_by_current_user: current_user ? current_user.greentea_like?(greentea) : false
        }
      end

      def greentea_detail(greentea, nearby_temples)
        greentea_summary(greentea).merge(
          phone_number: greentea.phone_number,
          business_hours: greentea.business_hours,
          holiday: greentea.holiday,
          homepage: greentea.homepage,
          closed: greentea.closed,
          nearby_temples: nearby_temples.map { |t| temple_nearby(t, greentea) },
          comments: greentea.greenteacomments.includes(:user).order(created_at: :desc).map { |c|
            {
              id: c.id,
              body: c.body,
              user: { id: c.user.id, name: c.user.name },
              created_at: c.created_at.iso8601
            }
          }
        )
      end

      def temple_nearby(temple, greentea)
        {
          id: temple.id,
          name: temple.name,
          address: temple.address,
          img: temple.img,
          distance_meters: greentea.get_distance(temple.latitude, temple.longitude)
        }
      end
    end
  end
end
