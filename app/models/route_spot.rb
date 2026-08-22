class RouteSpot < ApplicationRecord
  SPOT_TYPES = { 'greentea' => 'Greentea', 'temple' => 'Temple' }.freeze

  belongs_to :route, inverse_of: :route_spots
  belongs_to :spottable, polymorphic: true

  # 移動手段: 次のスポットへの移動手段。ユーザーが選ぶのではなく、区間距離と
  # Directions API の結果から自動決定される（DirectionsService.auto_leg）。
  # 次スポットが無い（最後のスポット）場合や算出失敗時は未設定（nil）のまま。
  # train/bus/car は過去に手動選択で保存されたレコードとの互換のために残しているが、
  # 自動決定では選ばれない（walk / transit のみ）。
  enum :transport, { walk: 0, train: 1, bus: 2, car: 3, transit: 4 }

  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validates :spottable_type, inclusion: { in: SPOT_TYPES.values }

  # API で受け取る "greentea" / "temple" を ActiveRecord のクラス名に変換する。
  def self.spottable_type_for(spot_type)
    SPOT_TYPES[spot_type.to_s]
  end

  # API で受け取る "greentea" / "temple" を ActiveRecord のモデルクラスに解決する。
  # ユーザー入力文字列を直接 constantize せず、allowlist (SPOT_TYPES) 経由でのみ解決する。
  # 未対応の spot_type は nil を返す。
  def self.spottable_class_for(spot_type)
    case spottable_type_for(spot_type)
    when 'Greentea' then Greentea
    when 'Temple' then Temple
    end
  end

  # ActiveRecord のクラス名を API の "greentea" / "temple" に戻す。
  def spot_type
    SPOT_TYPES.key(spottable_type)
  end
end
