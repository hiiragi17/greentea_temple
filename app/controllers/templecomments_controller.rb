class TemplecommentsController < ApplicationController
  skip_before_action :require_login, only: %i[index]

  def index
    @temple = Temple.find(params[:temple_id])
    @templecomment = Templecomment.new
    @temple_templecomments = @temple.templecomments.includes(:user).order(created_at: :desc)
  end

  def create
    templecomment = current_user.templecomments.build(templecomment_params)
    if templecomment.save
      redirect_to temple_templecomments_path, success: '口コミを作成しました'
    else
      redirect_to temple_templecomments_path, error: '口コミが投稿出来ませんでした'
    end
    # @templecomment = current_user.templecomments.build(templecomment_params)
    # @templecomment.save
  end

  # def edit 
  #   @templecomment = current_user.templecomments.find(params[:id])
  # end

  # def update
  #   @templecomment = current_user.templecomments.find(params[:id])
  #   if @templecomment.update(templecomment_params)
  #     redirect_to @templecomment, success: '口コミを編集しました'
  #   else
  #     flash.now['error'] = '口コミが編集できませんでした'
  #     render :edit
  #   end
  # end

  def destroy
    templecomment = current_user.templecomments.find(params[:id])
    templecomment.destroy!
    redirect_to templecomment_path, success: '口コミを削除しました'
    # @templecomment = current_user.templecomments.find(params[:id])
    # @templecomment.destroy!
  end

  private

  def templecomment_params
    params.require(:templecomment).permit(:body).merge(temple_id: params[:temple_id])
  end
end
