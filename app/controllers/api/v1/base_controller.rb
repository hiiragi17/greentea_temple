module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def current_user
        return @current_user if defined?(@current_user)

        header = request.headers['Authorization']
        return @current_user = nil unless header&.start_with?('Bearer ')

        token = header.split(' ').last
        decoded = JWT.decode(token, jwt_secret, true, algorithm: 'HS256')
        @current_user = User.find_by(id: decoded.first['user_id'])
      rescue JWT::DecodeError
        @current_user = nil
      end

      def require_authentication!
        render json: { error: '認証が必要です' }, status: :unauthorized unless current_user
      end

      def jwt_secret
        ENV.fetch('JWT_SECRET_KEY') { Rails.application.secret_key_base }
      end

      def render_not_found
        render json: { error: 'リソースが見つかりません' }, status: :not_found
      end

      def render_unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
