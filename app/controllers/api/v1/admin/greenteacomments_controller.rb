module Api
  module V1
    module Admin
      # admin は所有者チェックをバイパスして任意の口コミを削除できる。
      class GreenteacommentsController < BaseController
        def destroy
          comment = Greenteacomment.find(params[:id])
          comment.destroy!
          head :no_content
        end
      end
    end
  end
end
