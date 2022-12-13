class GreenteasController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index
    @search = Greentea.ransack(params[:q])
    @greenteas = @search.result(distinct: true).page(params[:page])
  end

  def show
    @greentea = Greentea.find(params[:id])
    @longitude = @greentea.longitude
    @latitude = @greentea.latitude
    gon.greentea = @greentea
    @temples = Temple.all.within(1.5, origin: [@latitude, @longitude]).by_distance(origin: [@latitude, @longitude])
    gon.temples = @temples
  end

  def greentea_likes
    @greentea_like_greenteas = current_user.greenteas.includes(:users).order(created_at: :desc)
  end

  private

  def greentea_params
    params.require(:greentea).permit(:name, :description, :access, :address, genre_ids: [])
  end
end
