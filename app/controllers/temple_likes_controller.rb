class TempleLikesController < ApplicationController
  def create
    temple = Temple.find(params[:temple_id])
    current_user.temple_like(temple)
    redirect_to temple_likes_path, success: t('.success')
  end

  def destroy
    temple = current_user.temple_likes.find(params[:id]).temple
    current_user.untemple_like(temple)
    redirect_to temples_path, success: t('.success')
  end
end
