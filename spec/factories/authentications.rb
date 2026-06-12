FactoryBot.define do
  factory :authentication do
    association :user
    provider { 'line' }
    # DB の (provider, uid) は NOT NULL かつ UNIQUE なので uid を一意に振る。
    sequence(:uid) { |n| format('U%016d', n) }
  end
end
