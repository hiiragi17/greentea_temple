FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "抹茶大好き#{n}号" }
    role { 0 }
  end
end
