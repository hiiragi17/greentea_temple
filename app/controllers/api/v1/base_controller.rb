module Api
  module V1
    class BaseController < ActionController::API
      before_action :set_default_format

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from StandardError, with: :render_internal_server_error if Rails.env.production?

      def route_not_found
        render json: { error: 'Not Found' }, status: :not_found
      end

      private

      def set_default_format
        request.format = :json
      end

      def render_not_found(exception = nil)
        Rails.logger.info(exception&.full_message) if exception
        render json: { error: 'Not Found' }, status: :not_found
      end

      def render_bad_request(exception = nil)
        Rails.logger.info(exception&.full_message) if exception
        render json: { error: 'Bad Request' }, status: :bad_request
      end

      def render_internal_server_error(exception = nil)
        Rails.logger.error(exception&.full_message) if exception
        render json: { error: 'Internal Server Error' }, status: :internal_server_error
      end
    end
  end
end
