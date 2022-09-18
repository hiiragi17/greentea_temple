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
  end
end