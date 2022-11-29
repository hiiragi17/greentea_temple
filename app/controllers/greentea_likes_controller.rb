class GreenteaLikesController < ApplicationController
  def create
    @greentea = Greentea.find(params[:greentea_id])
    current_user.greentea_like(@greentea)
  end

  def destroy
    @greentea = current_user.greentea_likes.find(params[:id]).greentea
    current_user.ungreentea_like(@greentea)
  end
end
