FactoryBot.define do
  factory :greenteacomment do
    association :user
    association :greentea
    body { '抹茶が濃厚でとても美味しかったです' }
  end
end
