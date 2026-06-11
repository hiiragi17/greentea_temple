FactoryBot.define do
  factory :route do
    association :user
    sequence(:name) { |n| "京都抹茶巡りルート#{n}" }
    description { '神社とお茶屋さんを巡るおすすめルート' }
  end
end
