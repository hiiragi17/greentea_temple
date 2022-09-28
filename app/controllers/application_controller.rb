class ApplicationController < ActionController::Base
  before_action :require_login

  add_flash_types :success, :error

  private

  def not_authenticated
    flash[:info] = 'ログインしてください'
    redirect_to main_app.root_path # main_appのプレフィックスをつける
  end
end
