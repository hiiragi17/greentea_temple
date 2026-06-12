FactoryBot.define do
  factory :greentea_like do
    association :user
    association :greentea
  end
end
