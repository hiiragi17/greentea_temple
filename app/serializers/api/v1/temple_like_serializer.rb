module Api
  module V1
    class TempleLikeSerializer
      include JSONAPI::Serializer

      attribute :created_at

      # いいねした神社本体は読み取り一覧と同形（TempleSerializer を再利用）に
      # liked_by_current_user を加えたもの。これは current_user 自身のいいね一覧なので常に true。
      attribute :temple do |like, params|
        spot = TempleSerializer.new(
          like.temple,
          params: { like_counts: params[:like_counts] }
        ).serializable_hash[:data]
        { id: spot[:id].to_i, **spot[:attributes], liked_by_current_user: true }
      end
    end
  end
end
