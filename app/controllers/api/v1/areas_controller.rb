module Api
  module V1
    class AreasController < BaseController
      def index
        render_simple_collection(Area.order(:id), serializer: AreaSerializer)
      end
    end
  end
end
