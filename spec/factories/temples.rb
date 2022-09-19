FactoryBot.define do
  factory :temple do
    sequence(:name) { |n| "神社仏閣#{n}号店" }
    sequence(:description) { |n| "神社仏閣#{n}社がある" }
    phone_number { 075-371-5181 }
    address { "〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内" }
    access { "ＪＲ「京都」駅から徒歩約15分（タクシー5分)" }
    business_hours { "開門時間5：30～17：00" }
    homepage { "http://www.hongwanji.kyoto" }
    holiday { "水曜日" }
    sequence(:latitude) { |n| "34.9926#{n}" }
    sequence(:longitude) { |n| "135.7535#{n}" }

    trait :gan do
      sequence(:name) { |n| "神社仏閣#{n}願号店" }
      sequence(:description) { |n| "神社仏閣#{n}社がある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { "〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内" }
      access { "ＪＲ「京都」駅から徒歩約15分（タクシー5分)" }
     end

     trait :kouyou do
      sequence(:name) { |n| "神社仏閣#{n}号店" }
      sequence(:description) { |n| "神社仏閣#{n}社紅葉がある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { "〒605-0074 京都府京都市東山区祇園町南側５８６" }
      access { "ＪＲ「京都」駅から徒歩約15分（タクシー5分)" }
     end

     trait :husimi do
      sequence(:name) { |n| "神社仏閣#{n}号店" }
      sequence(:description) { |n| "神社仏閣#{n}社がある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { "〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内" }
      access { "ＪＲ「京都」駅から徒歩約15分（タクシー5分)" }
     end

     trait :uzi do
      sequence(:name) { |n| "神社仏閣#{n}号店" }
      sequence(:description) { |n| "神社仏閣#{n}社がある" }
      sequence(:latitude) { |n| "34.9676#{n}" }
      sequence(:longitude) { |n| "135.7741#{n}" }
      address { "〒612-0805 京都府京都市伏見区深草藪之内町６８ 伏見稲荷大社啼鳥菴内" }
      access { "京阪宇治線「宇治駅」から徒歩約5分JR奈良線「宇治駅」から徒歩約15分" }
     end
  end
end