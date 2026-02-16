module Api
  module V1
    class CurrentUserController < BaseController
      before_action :require_authentication!

      def show
        render json: {
          data: {
            id: current_user.id,
            name: current_user.name,
            role: current_user.role
          }
        }
      end
    end
  end
end
