class TemplesController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index
    @search = Temple.ransack(params[:q])
    @temples = @search.result(distinct: true).page(params[:page])
  end

  def show
    @temple = Temple.find(params[:id])
    @longitude = @temple.longitude
    @latitude = @temple.latitude
    gon.temple = @temple
    @greenteas = Greentea.all.within(1.5, origin: [@latitude, @longitude]).by_distance(origin: [@latitude, @longitude])
    gon.greenteas = @greenteas
  end

  def temple_likes
    @temple_like_temples = current_user.temples.includes(:users).order(created_at: :desc)
  end

  private

  def temple_params
    params.require(:greentea).permit(:name, :description, :access, :address, area_ids: [])
  end
end
