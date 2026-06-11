FactoryBot.define do
  factory :route_spot do
    association :route
    association :spottable, factory: :greentea
    sequence(:position) { |n| n }
    transport { nil }
  end
end
