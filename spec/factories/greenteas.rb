FactoryBot.define do
  factory :greentea do
    sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
    sequence(:description) { |n| "美味しい抹茶#{n}メニューがある" }
    phone_number { 0o75 - 286 - 3631 }
    address { '〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内' }
    access { 'JR奈良線「稲荷駅」から徒歩約5分' }
    business_hours { '11:00~16:00(L.O.15:30)' }
    homepage { 'https://tsubakido.kyoto/inarisaryo/' }
    holiday { '水曜日' }
    sequence(:latitude) { |n| "34.9676#{n}" }
    sequence(:longitude) { |n| "135.7741#{n}" }

    trait :gion do
      sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
      sequence(:description) { |n| "美味しい抹茶#{n}メニューがある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { '〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内' }
      access { 'JR奈良線「稲荷駅」から徒歩約5分' }
    end

    trait :cake do
      sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
      sequence(:description) { |n| "美味しい抹茶#{n}ケーキメニューがある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { '〒611-0013 京都府宇治市莵道荒槇１９−３' }
      access { 'JR奈良線「稲荷駅」から徒歩約5分' }
    end

    trait :husimi do
      sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
      sequence(:description) { |n| "美味しい抹茶#{n}メニューがある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { '〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内' }
      access { 'JR奈良線「稲荷駅」から徒歩約5分' }
    end

    trait :uzi do
      sequence(:name) { |n| "抹茶スイーツ#{n}号店" }
      sequence(:description) { |n| "美味しい抹茶#{n}メニューがある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { '〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内' }
      access { '京阪宇治線「宇治駅」から徒歩約5分JR奈良線「宇治駅」から徒歩約15分' }
    end
  end
end
