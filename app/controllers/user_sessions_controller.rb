class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new login_as]
  def new; end

  def destroy
    logout
    redirect_to(root_path, success: t('.success'))
  end

  def login_as
    user = User.find(params[:user_id])
    auto_login(user)
    redirect_to root_path, success: "#{Rails.env}環境でログインしました"
  end
end
