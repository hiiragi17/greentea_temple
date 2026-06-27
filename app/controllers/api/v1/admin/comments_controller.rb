module Api
  module V1
    module Admin
      # 抹茶店・神社の口コミを横断して一覧するモデレーション用エンドポイント。
      # type（greentea / temple）と spot_id で絞り込める。
      #
      # 2 テーブルを跨ぐため AR の relation 1 本では取得できない。全件ロードを避けるため、
      # 各ソースから「先頭ページ〜要求ページ末尾まで（page * per_page 件）」だけを
      # created_at 降順で DB 側に絞って取得し、メモリ上でマージ・整列してから
      # 該当ページ分を切り出す。total_count は各ソースの COUNT を合算する。
      class CommentsController < BaseController
        def index
          window = page_window
          render json: {
            comments: window.map { |comment| serialize_comment(comment) },
            meta: pagination_meta
          }
        end

        private

        def page_window
          merged = merged_comments
          offset = (current_page - 1) * per_page
          merged[offset, per_page] || []
        end

        # 各ソースを page * per_page 件に絞って取得し、降順マージした上位 page * per_page 件。
        # これにより全体の上位 N 件が必ずこの集合に含まれる（各ソースの上位 N 件の和集合）。
        def merged_comments
          limit = current_page * per_page
          records = []
          records.concat(greenteacomments_scope.order(created_at: :desc).limit(limit).to_a) if include_type?('greentea')
          records.concat(templecomments_scope.order(created_at: :desc).limit(limit).to_a) if include_type?('temple')
          records.sort_by(&:created_at).reverse.first(limit)
        end

        def pagination_meta
          {
            current_page: current_page,
            total_pages: total_count.zero? ? 0 : (total_count.to_f / per_page).ceil,
            total_count: total_count
          }
        end

        def total_count
          @total_count ||= begin
            count = 0
            count += greenteacomments_scope.count if include_type?('greentea')
            count += templecomments_scope.count if include_type?('temple')
            count
          end
        end

        def current_page
          page = params[:page].to_i
          page < 1 ? 1 : page
        end

        def include_type?(type)
          params[:type].blank? || params[:type] == type
        end

        def greenteacomments_scope
          scope = Greenteacomment.includes(:user)
          scope = scope.where(greentea_id: params[:spot_id]) if params[:spot_id].present?
          scope
        end

        def templecomments_scope
          scope = Templecomment.includes(:user)
          scope = scope.where(temple_id: params[:spot_id]) if params[:spot_id].present?
          scope
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
