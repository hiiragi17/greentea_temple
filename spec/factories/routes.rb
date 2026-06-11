FactoryBot.define do
  factory :route do
    association :user
    sequence(:name) { |n| "京都抹茶巡りルート#{n}" }
    description { '神社とお茶屋さんを巡るおすすめルート' }

    # Route は最低 1 スポット必須なので、デフォルトで 1 件持たせて有効な状態にする。
    after(:build) do |route|
      route.route_spots << build(:route_spot, route: route, position: 1) if route.route_spots.empty?
    end
  end
end
