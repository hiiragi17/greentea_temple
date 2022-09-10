class TemplesController < ApplicationController
  def index
    @search = Temple.ransack(params[:q])
    @temples = @search.result(distinct: true).page(params[:page])
  end

  def show
    @temple = Temple.find(params[:id])
  end

  private
  def temple_params
    params.require(:greentea).permit(:name, :description, :access, :address, area_ids: [])
  end

end