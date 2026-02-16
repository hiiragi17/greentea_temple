module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      private

      def authenticate_user!
        token = extract_token
        return render_unauthorized unless token

        decoded = JsonWebToken.decode(token)
        return render_unauthorized unless decoded

        @current_user = User.find_by(id: decoded[:user_id])
        render_unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def extract_token
        header = request.headers['Authorization']
        header&.split(' ')&.last
      end

      def render_unauthorized
        render json: { error: '認証が必要です' }, status: :unauthorized
      end

      def render_not_found(resource = 'リソース')
        render json: { error: "#{resource}が見つかりません" }, status: :not_found
      end

      def render_unprocessable(errors)
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end
  end
end
