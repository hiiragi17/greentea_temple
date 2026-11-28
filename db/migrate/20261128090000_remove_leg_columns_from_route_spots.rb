class RemoveLegColumnsFromRouteSpots < ActiveRecord::Migration[8.1]
  # 移動手段・経路距離・所要時間・経路ポリラインは使わなくなった（行き方はフロントから
  # Google マップのリンクに任せる）。RouteSpot の ignored_columns でこれらの列を参照しない
  # コードを先にデプロイしてから、このマイグレーションをデプロイすること（デプロイでは
  # db:migrate が新リビジョン投入前に走るため、古いコードがまだ列を参照していると 500 になる）。
  def change
    remove_column :route_spots, :transport, :integer
    remove_column :route_spots, :leg_distance_meters, :integer
    remove_column :route_spots, :leg_duration_seconds, :integer
    remove_column :route_spots, :leg_polyline, :text
  end
end
