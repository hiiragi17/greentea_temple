class ApplicationController < ActionController::Base
  before_action :require_login

  add_flash_types :success, :error, :info

  private

  # def not_authenticated
  #   redirect_to main_app.login_path, info: t('defaults.message.require_login')  # main_appのプレフィックスをつける
  # end
end
