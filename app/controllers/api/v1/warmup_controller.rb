module Api
  module V1
    class WarmupController < BaseController
      before_action :authenticate_warmup_token!

      def show
        ActiveRecord::Base.connection.execute('SELECT 1')
        render json: { status: 'ok' }
      end

      private

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
