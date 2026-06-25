module Api
  module V1
    class GreenteaLikeSerializer
      include JSONAPI::Serializer

      attribute :created_at

      # いいねした抹茶店本体は読み取り一覧と同形（GreenteaSerializer を再利用）に
      # liked_by_current_user を加えたもの。これは current_user 自身のいいね一覧なので常に true。
      attribute :greentea do |like, params|
        spot = GreenteaSerializer.new(
          like.greentea,
          params: { like_counts: params[:like_counts] }
        ).serializable_hash[:data]
        { id: spot[:id].to_i, **spot[:attributes], liked_by_current_user: true }
      end
    end
  end
end
