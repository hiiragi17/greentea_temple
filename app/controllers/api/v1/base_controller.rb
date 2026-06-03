module Api
  module V1
    class BaseController < ActionController::API
      DEFAULT_PER_PAGE = 15
      MAX_PER_PAGE = 100

      before_action :set_default_format

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from StandardError, with: :render_internal_server_error if Rails.env.production?

      def route_not_found
        render json: { error: 'Not Found' }, status: :not_found
      end

      private

      def paginate(scope)
        per_page = params[:per_page].to_i
        per_page = DEFAULT_PER_PAGE if per_page <= 0
        per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE
        scope.page(params[:page]).per(per_page)
      end

      def render_collection(records, serializer:, serializer_params: {})
        serialized = serializer.new(records.to_a, params: serializer_params).serializable_hash
        render json: {
          data: flatten_serialized(serialized[:data]),
          meta: pagination_meta(records)
        }
      end

      def render_resource(record, serializer:, serializer_params: {})
        serialized = serializer.new(record, params: serializer_params).serializable_hash
        render json: { data: flatten_serialized(serialized[:data]) }
      end

      def pagination_meta(records)
        {
          current_page: records.current_page,
          total_pages: records.total_pages,
          total_count: records.total_count,
          per_page: records.limit_value
        }
      end

      def flatten_serialized(data)
        if data.is_a?(Array)
          data.map { |d| flatten_one(d) }
        else
          flatten_one(data)
        end
      end

      def flatten_one(payload)
        return nil unless payload

        { id: payload[:id].to_i }.merge(payload[:attributes] || {})
      end

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
