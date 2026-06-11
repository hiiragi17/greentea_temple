class AddLegMetricsToRouteSpots < ActiveRecord::Migration[7.0]
  def change
    # 次のスポットまでの経路距離・所要時間（Directions API の算出結果）。
    # 最後のスポットや算出失敗時は null。
    change_table :route_spots, bulk: true do |t|
      t.integer :leg_distance_meters
      t.integer :leg_duration_seconds
    end
  end
end
