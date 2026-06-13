module Api
  module V1
    class GenresController < BaseController
      def index
        render_full_collection(Genre.order(:id), serializer: GenreSerializer)
      end
    end
  end
end
