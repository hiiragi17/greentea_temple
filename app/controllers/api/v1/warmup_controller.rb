module Api
  module V1
    class WarmupController < BaseController
      before_action :authenticate_warmup_token!

      def show
        ActiveRecord::Base.connection.execute('SELECT 1')
        render json: { status: 'ok', pending_migrations: pending_migrations? }
      end

      private

      # デプロイでは db:migrate が自動実行されるが（.github/workflows/deploy-cloud-run.yml）、
      # 手動デプロイやロールバックでコードと本番スキーマがずれると、特定の API だけが
      # 500 になり原因を切り分けづらい（例: route_spots.leg_polyline 未適用で
      # モデルコースの取得・作成が落ちる）。トークン保護済みのこのエンドポイントで
      # 未適用 migration の有無を返し、外から即座に確認できるようにする。
      # 判定自体に失敗しても warmup は落とさず nil を返す。
      def pending_migrations?
        ActiveRecord::Base.connection_pool.migration_context.needs_migration?
      rescue StandardError => e
        Rails.logger.warn("pending migration check failed: #{e.class} #{e.message}")
        nil
      end

      # Cloud Scheduler からの呼び出しのみに限定する。誰でも叩ける状態だと
      # 連打によって Neon のオートサスペンド復帰・負荷・課金を誘発しうるため。
      # WARMUP_TOKEN が未設定の場合は空文字同士の比較で誤って通ってしまわないよう、
      # blank? を先にチェックして fail closed にする。
      def authenticate_warmup_token!
        expected = ENV['WARMUP_TOKEN'].to_s
        token = request.headers['X-Warmup-Token'].to_s
        return render json: { error: 'Unauthorized' }, status: :unauthorized if expected.blank?

        render json: { error: 'Unauthorized' }, status: :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(token, expected)
      end
    end
  end
end
