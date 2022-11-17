class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new]
  before_action :set_user, only: %i[show edit update destroy]

  def new
    @user = User.new
  end

  def edit; end

  def show
    if @user == current_user
      render 'show'
    else
      render404
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
    current_user.destroy!
    redirect_to root_path, success: t('.success')
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :role)
  end
end
