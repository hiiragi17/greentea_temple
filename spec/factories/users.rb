FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "抹茶大好き#{n}号" }
    sequence(:email) { |n| "greentea#{n}@example.com" }
    password { 'password' }
    password_confirmation { 'password' }
    role { 0 }
  end
end
