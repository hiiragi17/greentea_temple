module Api
  module V1
    module Admin
      # 管理用 API の共通基底。全エンドポイントで admin 認可を必須にする。
      class BaseController < Api::V1::BaseController
        before_action :require_admin!

        private

        def render_unprocessable(record)
          render json: { errors: record.errors.messages }, status: :unprocessable_entity
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
