# Be sure to restart your server when you modify this file.
#
# `config/application.rb` で `config.load_defaults 8.1` を設定済みのため、
# Rails 8.1 の新しい framework defaults は **すべて有効** になっている。
#
# このファイルは「新挙動を個別に元へ戻す（opt-out する）」ための退避口として残している。
# 本番で問題が出た項目だけコメントを外して旧挙動へ戻し、原因対処後に再度コメントへ戻すこと。
# 問題がないと確認できたら、このファイルごと削除してよい。
#
# 詳細: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# JSON レンダラで HTML エンティティ / 行区切り文字をエスケープしなくなった（高速化）。
# 旧挙動（エスケープする）に戻す場合:
# Rails.configuration.action_controller.escape_json_responses = true

###
# JSON 内の LINE/PARAGRAPH SEPARATOR (U+2028/U+2029) をエスケープしなくなった。
# 旧挙動に戻す場合:
# Rails.configuration.active_support.escape_js_separators_in_json = true

###
# order 指定なしで `#first` / `#second` 等を呼ぶと（並び順の手掛かりが無いモデルで）例外を上げる。
# 旧挙動（例外を上げない）に戻す場合:
# Rails.configuration.active_record.raise_on_missing_required_finder_order_columns = false

###
# 先頭スラッシュの無い相対 URL への redirect_to を `:raise`（UnsafeRedirectError）にする。
# 例: redirect_to "example.com" / redirect_to "@attacker.com" は例外。redirect_to "/safe/path" は OK。
# 旧挙動に戻す場合（警告ログのみ / 通知）:
# Rails.configuration.action_controller.action_on_path_relative_redirect = :log

###
# Action View テンプレート間の依存追跡に Ruby パーサを使う。
# 旧挙動に戻す場合:
# Rails.configuration.action_view.render_tracker = :regexp

###
# form_tag / button_to 等が生成する hidden input から autocomplete="off" を出力しなくなった。
# 旧挙動（autocomplete 属性を付与）に戻す場合:
# Rails.configuration.action_view.remove_hidden_field_autocomplete = false
