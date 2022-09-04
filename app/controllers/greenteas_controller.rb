class GreenteasController < ApplicationController
  def index
    @search = Greentea.ransack(params[:q])
    @greenteas = @search.result(distinct: true).page(params[:page])
  end

  def show
    @greentea = Greentea.find(params[:id])
  end

  private
  def greentea_params
    params.require(:greentea).permit(:name, :description, :access, :address, genre_ids: [])
  end

end
