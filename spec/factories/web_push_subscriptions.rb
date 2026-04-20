FactoryBot.define do
  factory :web_push_subscription do
    user
    endpoint { "https://example.test/push/#{SecureRandom.uuid}" }
    p256dh { "p256dh-key" }
    auth { "auth-key" }
  end
end
