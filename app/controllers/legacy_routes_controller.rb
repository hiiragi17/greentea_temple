# 旧 Rails 製 Web フロント（#136 段階1）の撤去に伴うエンドポイント。
#
# 抹茶店／神社の閲覧・いいね・口コミ・現在地検索は API(/api/v1) と
# Next.js フロント（matcha-to-jinja）へ移行済みのため、対応する HTML ルートを
# 410 Gone で無効化する。コントローラ／ビュー本体の削除は後続段階（#136 段階2・3）で行う。
#
# 認証の有無に関わらず 410 を返したいので require_login をスキップし、
# CSRF トークン無しの POST / DELETE でも確実に 410 を返すため forgery protection もスキップする。
class LegacyRoutesController < ApplicationController
  skip_before_action :require_login, raise: false
  skip_forgery_protection

  GONE_MESSAGE = 'このページは廃止されました。API(/api/v1) または新フロントエンドをご利用ください。'.freeze

  def gone
    respond_to do |format|
      format.json { render json: { error: 'gone', message: GONE_MESSAGE }, status: :gone }
      format.any { render plain: GONE_MESSAGE, status: :gone, content_type: 'text/plain' }
    end
  end
end
