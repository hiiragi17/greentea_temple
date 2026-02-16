module Api
  module V1
    class GenresController < BaseController
      def index
        genres = Genre.all.order(:name)
        render json: {
          data: genres.map { |g| { id: g.id, name: g.name } }
        }
      end
    end
  end
end
