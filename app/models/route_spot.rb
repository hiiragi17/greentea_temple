class RouteSpot < ApplicationRecord
  SPOT_TYPES = { 'greentea' => 'Greentea', 'temple' => 'Temple' }.freeze

  belongs_to :route, inverse_of: :route_spots
  belongs_to :spottable, polymorphic: true

  # 移動手段・経路距離・所要時間・経路ポリラインの列は使わなくなった（Directions API は
  # 日本の乗換案内を返さず不正確だったため、行き方はフロントから Google マップに任せる）。
  # 列の削除マイグレーションをデプロイする前に、動いているコードがこれらの列を参照しない
  # ようにするため無視する。列の削除後に ignored_columns も外す。
  self.ignored_columns += %w[transport leg_distance_meters leg_duration_seconds leg_polyline]

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
