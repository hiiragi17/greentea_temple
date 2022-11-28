class TempleLikesController < ApplicationController
  def create
    @temple = Temple.find(params[:temple_id])
    current_user.temple_like(@temple)
  end

  def destroy
    @temple = current_user.temple_likes.find(params[:id]).temple
    current_user.untemple_like(@temple)
  end
end
