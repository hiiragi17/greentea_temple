module Api
  module V1
    class CurrentUserController < BaseController
      before_action :require_authentication!

      def show
        render json: { user: serialize_user_payload(current_user) }
      end
    end
  end
end
