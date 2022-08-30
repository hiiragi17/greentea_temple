class GreenteasController < ApplicationController
  def index
    @search = Greentea.ransack(params[:q])
    @greenteas = @search.result(distinct: true).page(params[:page])
  end

  def show
    @greentea =Greentea.find(params[:id])
  end

  private
  def greeentea_params
    params.require(:greentea).permit(:name, :description)
  end

end
