module Api
  module V1
    class CurrentUserController < BaseController
      before_action :require_authentication!

      def show
        render json: { user: serialize_user_payload(current_user) }
      end

      def update
        if current_user.update(user_params)
          render json: { user: serialize_user_payload(current_user) }
        else
          render json: { error: current_user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name)
      end
    end
  end
end
