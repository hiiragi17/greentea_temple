module Api
  module V1
    class BaseController < ActionController::API
      DEFAULT_PER_PAGE = 15
      MAX_PER_PAGE = 100

      prepend_before_action :set_no_store_cache_headers
      before_action :set_default_format

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from StandardError, with: :render_internal_server_error if Rails.env.production?

      def route_not_found
        render json: { error: 'Not Found' }, status: :not_found
      end

      def current_user
        return @current_user if defined?(@current_user)

        @current_user = authenticate_with_token
      end

      def require_authentication!
        return if current_user

        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      # 管理用 API の認可境界。未認証は 401 / admin 以外は 403 で弾く。
      def require_admin!
        return render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
        return if current_user.admin?

        render json: { error: 'Forbidden' }, status: :forbidden
      end

      private

      def authenticate_with_token
        token = bearer_token
        return nil if token.blank?

        payload = JwtService.decode(token)
        User.find_by(id: payload['user_id'])
      rescue JwtService::Error => e
        Rails.logger.info("JWT auth failed: #{e.class} #{e.message}")
        nil
      end

      def bearer_token
        header = request.headers['Authorization']
        return nil unless header.is_a?(String)
        return nil unless header.start_with?('Bearer ')

        header.split(' ', 2).last
      end

      def serialize_user_payload(user)
        serialized = UserSerializer.new(user).serializable_hash
        flatten_one(serialized[:data])
      end

      def paginate(scope)
        scope.page(params[:page]).per(per_page)
      end

      # 複数条件（OR）検索対応。
      # 「パフェ かき氷」のように空白/読点区切りで複数キーワードを渡された場合、
      # Ransack の `_any` / `_all` 複合述語（例: name_cont_any）に配列として渡す。
      # 例: q[name_cont_any]=パフェ かき氷 → ["パフェ", "かき氷"] で OR 検索
      # 対象は述語サフィックスが _any / _all のキーのみ（他のキーの空白はそのまま渡す）。
      MULTI_VALUE_PREDICATE_SUFFIXES = %w[_any _all].freeze
      KEYWORD_DELIMITER = /[[:space:],、]+/

      def normalize_ransack_params(ransack_params)
        return ransack_params if ransack_params.blank?

        hash = ransack_params.respond_to?(:to_unsafe_h) ? ransack_params.to_unsafe_h : ransack_params.to_h
        hash.each_with_object({}) do |(key, value), normalized|
          normalized[key] = split_multi_keyword_value(key, value)
        end
      end

      def split_multi_keyword_value(key, value)
        return value unless value.is_a?(String)
        return value unless MULTI_VALUE_PREDICATE_SUFFIXES.any? { |suffix| key.to_s.end_with?(suffix) }

        value.split(KEYWORD_DELIMITER).reject(&:blank?)
      end

      def per_page
        value = params[:per_page].to_i
        return DEFAULT_PER_PAGE if value <= 0
        return MAX_PER_PAGE if value > MAX_PER_PAGE

        value
      end

      def render_collection(records, serializer:, root: :data, serializer_params: {})
        serialized = serializer.new(records.to_a, params: serializer_params).serializable_hash
        render json: {
          root => flatten_serialized(serialized[:data]),
          meta: pagination_meta(records)
        }
      end

      def render_resource(record, serializer:, root: :data, serializer_params: {}, status: :ok)
        serialized = serializer.new(record, params: serializer_params).serializable_hash
        render json: { root => flatten_serialized(serialized[:data]) }, status: status
      end

      # ジャンル / エリアのような件数の少ない参照リストはページネーションせず全件返す。
      # フロントの絞り込み選択肢が欠落しないよう meta は付けない。
      # NOTE: 全件をメモリにロードするため、件数の少ない参照リスト専用。
      #       大量データを持つテーブルには使わないこと（一覧は render_collection を使う）。
      def render_full_collection(records, serializer:, root: :data, serializer_params: {})
        serialized = serializer.new(records.to_a, params: serializer_params).serializable_hash
        render json: { root => flatten_serialized(serialized[:data]) }
      end

      def pagination_meta(records)
        {
          current_page: records.current_page,
          total_pages: records.total_pages,
          total_count: records.total_count
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

      # ブラウザが GET レスポンスを ETag/条件付きGETでキャッシュし、
      # 更新後も古いデータを 304 で返してしまうのを防ぐ（例: いいね一覧）。
      # after_action だと例外(rescue_from)や別の before_action の render で
      # 途中終了した際にスキップされるため、必ず先頭で実行されるようprepend_before_actionを使う。
      def set_no_store_cache_headers
        response.headers['Cache-Control'] = 'no-store'
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
