module Api
  module V1
    class CurrentUserController < BaseController
      before_action :require_authentication!

      def show
        render json: { data: serialize_user_payload(current_user) }
      end
    end
  end
end
