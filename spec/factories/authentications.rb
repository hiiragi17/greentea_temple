FactoryBot.define do
  factory :authentication do
    association :user
    provider { 'google' }
    sequence(:uid) { |n| "uid-#{n}" }
  end
end
