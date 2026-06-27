module Api
  module V1
    module Admin
      # 管理用 API の共通基底。全エンドポイントで admin 認可を必須にする。
      class BaseController < Api::V1::BaseController
        before_action :require_admin!

        # latitude/longitude のような NOT NULL カラムを欠いた作成・更新は DB 例外になる。
        # 既存 Web フローの geocode（after_validation でカラムを埋める）を壊さないよう
        # モデルへ presence 検証を足さず、API 層で 422 に変換する。
        rescue_from ActiveRecord::NotNullViolation, with: :render_not_null_violation

        private

        def render_unprocessable(record)
          render json: { errors: record.errors.messages }, status: :unprocessable_entity
        end

        def render_not_null_violation(exception)
          Rails.logger.info("Admin API NOT NULL violation: #{exception.message}")
          render json: { errors: { base: ['必須項目が入力されていません'] } },
                 status: :unprocessable_entity
        end

        # フロントは closed を boolean で送るが、DB は integer（0/1）で保持する。
        def normalize_closed(value)
          return 1 if [true, 'true', 1, '1'].include?(value)
          return 0 if [false, 'false', 0, '0'].include?(value)

          value
        end
      end
    end
  end
end
