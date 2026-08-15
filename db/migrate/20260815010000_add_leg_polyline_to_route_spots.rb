class AddLegPolylineToRouteSpots < ActiveRecord::Migration[7.1]
  def change
    # 次のスポットまでの経路ポリライン（Directions API の overview_polyline.points。
    # Google エンコード済みポリライン形式）。最後のスポットや算出失敗時は null。
    add_column :route_spots, :leg_polyline, :text
  end
end
