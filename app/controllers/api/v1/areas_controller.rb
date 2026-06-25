module Api
  module V1
    class AreasController < BaseController
      def index
        render_full_collection(Area.order(:id), serializer: AreaSerializer, root: :areas)
      end
    end
  end
end
