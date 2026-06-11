class RouteSpot < ApplicationRecord
  SPOT_TYPES = { 'greentea' => 'Greentea', 'temple' => 'Temple' }.freeze

  belongs_to :route, inverse_of: :route_spots
  belongs_to :spottable, polymorphic: true

  # 移動手段（任意）: 次のスポットへの移動手段。未設定可。
  enum transport: { walk: 0, train: 1, bus: 2, car: 3 }

  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validates :spottable_type, inclusion: { in: SPOT_TYPES.values }

  # API で受け取る "greentea" / "temple" を ActiveRecord のクラス名に変換する。
  def self.spottable_type_for(spot_type)
    SPOT_TYPES[spot_type.to_s]
  end

  # ActiveRecord のクラス名を API の "greentea" / "temple" に戻す。
  def spot_type
    SPOT_TYPES.key(spottable_type)
  end
end
