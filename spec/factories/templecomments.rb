FactoryBot.define do
  factory :templecomment do
    association :user
    association :temple
    body { '静かで落ち着いた良い神社でした' }
  end
end
