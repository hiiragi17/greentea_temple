module Api
  module V1
    module Admin
      # 抹茶店・神社の口コミを横断して一覧するモデレーション用エンドポイント。
      # type（greentea / temple）と spot_id で絞り込める。
      class CommentsController < BaseController
        def index
          comments = collect_comments
          paginated = Kaminari.paginate_array(comments).page(params[:page]).per(per_page)

          render json: {
            comments: paginated.map { |comment| serialize_comment(comment) },
            meta: pagination_meta(paginated)
          }
        end

        private

        def collect_comments
          records = []
          records.concat(greenteacomments_scope) if include_type?('greentea')
          records.concat(templecomments_scope) if include_type?('temple')
          records.sort_by(&:created_at).reverse
        end

        def include_type?(type)
          params[:type].blank? || params[:type] == type
        end

        def greenteacomments_scope
          scope = Greenteacomment.includes(:user)
          scope = scope.where(greentea_id: params[:spot_id]) if params[:spot_id].present?
          scope.to_a
        end

        def templecomments_scope
          scope = Templecomment.includes(:user)
          scope = scope.where(temple_id: params[:spot_id]) if params[:spot_id].present?
          scope.to_a
        end

        def serialize_comment(comment)
          base = {
            id: comment.id,
            body: comment.body,
            created_at: comment.created_at,
            user: { id: comment.user_id, name: comment.user&.name }
          }

          if comment.is_a?(Greenteacomment)
            base.merge(type: 'greentea', greentea_id: comment.greentea_id)
          else
            base.merge(type: 'temple', temple_id: comment.temple_id)
          end
        end
      end
    end
  end
end
