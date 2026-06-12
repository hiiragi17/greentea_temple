FactoryBot.define do
  factory :greenteacomment do
    association :user
    association :greentea
    body { 'とても美味しい抹茶パフェでした。また行きたいです。' }
  end
end
