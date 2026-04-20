# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Web push subscriptions", type: :request do
  def sign_in!(user, password: "Password123!")
    post sign_in_path, params: { email: user.email, password: password }
    expect(response).to have_http_status(:found)
  end

  # [REQ-HAB-012]
  it "creates or updates a subscription for the current user" do
    user = create(:user)
    sign_in!(user, password: "Password123!")

    expect {
      post web_push_subscription_path, params: {
        subscription: {
          endpoint: "https://example.test/push/123",
          p256dh: "p256dh-key",
          auth: "auth-key"
        }
      }
    }.to change(WebPushSubscription, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(user.web_push_subscriptions.count).to eq(1)
  end

  # [REQ-HAB-012]
  it "allows multiple subscriptions per user (different endpoints)" do
    user = create(:user)
    sign_in!(user, password: "Password123!")

    post web_push_subscription_path, params: { subscription: { endpoint: "https://e1", p256dh: "k1", auth: "a1" } }
    post web_push_subscription_path, params: { subscription: { endpoint: "https://e2", p256dh: "k2", auth: "a2" } }

    expect(response).to have_http_status(:ok)
    expect(user.web_push_subscriptions.count).to eq(2)
  end

  # [REQ-HAB-012]
  it "unsubscribes by endpoint" do
    user = create(:user)
    sign_in!(user, password: "Password123!")

    create(:web_push_subscription, user: user, endpoint: "https://e1", p256dh: "k1", auth: "a1")

    expect {
      delete web_push_subscription_path, params: { endpoint: "https://e1" }
    }.to change(WebPushSubscription, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end
end

