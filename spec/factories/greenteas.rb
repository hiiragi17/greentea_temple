FactoryBot.define do
  factory :greentea do
    sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
    sequence(:description) { |n| "美味しい抹茶#{n}メニューがある" }
    phone_number { 075-286-3631 }
    address { "〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内" }
    access { "JR奈良線「稲荷駅」から徒歩約5分" }
    business_hours { "11:00~16:00(L.O.15:30)" }
    homepage { "https://tsubakido.kyoto/inarisaryo/" }
    holiday { "水曜日" }
    sequence(:latitude) { |n| "34.9676#{n}" }
    sequence(:longitude) { |n| "135.7741#{n}" }
  end
end