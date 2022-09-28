class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :set_user, only: %i[ show edit update destroy ]

  def new
    @user = User.new
  end

  def edit; end

  def show; end
  
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to login_path, success: t('.success') 
    else
    flash.now[:error] = t('.fail')
    render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to user_url(@user), success: t('.success') 
    else
      flash.now[:error] = t('.error')
      render :edit
    end
  end

  def destroy
    @user.destroy!
    redirect_to users_url, success: t('.success'), status: :see_other 
  end
  
  private
    def set_user
      @user = User.find(params[:id])
    end
  
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
    end
end