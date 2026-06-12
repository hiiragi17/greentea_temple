FactoryBot.define do
  factory :temple_like do
    association :user
    association :temple
  end
end
