module Api
  module V1
    class AreasController < BaseController
      def index
        areas = Area.all.order(:name)
        render json: {
          data: areas.map { |a| { id: a.id, name: a.name } }
        }
      end
    end
  end
end
