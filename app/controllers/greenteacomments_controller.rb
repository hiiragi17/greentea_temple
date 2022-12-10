class GreenteacommentsController < ApplicationController
  skip_before_action :require_login, only: %i[index]

  def index
    @greentea = Greentea.find(params[:greentea_id])
    @greenteacomment = Greenteacomment.new
    @greentea_greenteacomments = @greentea.greenteacomments.includes(:user).order(created_at: :desc)
  end

  def create
    greenteacomment = current_user.greenteacomments.build(greenteacomment_params)
    if greenteacomment.save
      redirect_to greentea_greenteacomments_path, success: '口コミを作成しました'
    else
      redirect_to greentea_greenteacomments_path, error: t('defaults.message.not_created')
    end
    # @greenteacomment = current_user.greenteacomments.build(greenteacomment_params)
    # @greenteacomment.save
  end

  def destroy
    greenteacomment = current_user.greenteacomments.find(params[:id])
    greenteacomment.destroy!
    redirect_to greentea_path, success: '口コミを削除しました'
    # @greenteacomment = current_user.greenteacomments.find(params[:id])
    # @greenteacomment.destroy!
  end

  private

  def greenteacomment_params
    params.require(:greenteacomment).permit(:body).merge(greentea_id: params[:greentea_id])
  end
end
