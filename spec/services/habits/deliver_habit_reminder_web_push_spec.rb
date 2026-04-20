# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::DeliverHabitReminderWebPush do
  let(:user) { create(:user) }
  let(:category) { create(:habit_category, user: user) }
  let(:habit) do
    create(:user_habit,
      user: user,
      habit_category: category,
      active: true,
      frequency_type: "daily",
      frequency_params: {},
      reminder_enabled: true,
      reminder_time_of_day: "08:30",
      reminder_email: false,
      reminder_web_push: true)
  end

  let(:push_client) { double("WebPushClient") }
  let(:vapid_hash) { Habits::VapidConfig.from_application.to_web_push_hash }
  let(:message) { Habits::WebPushNotificationPayload.from_user_habit(habit).to_message_string }

  before do
    allow(push_client).to receive(:payload_send)
  end

  # [REQ-HAB-013]
  it "calls the push client once per subscription with payload and VAPID options" do
    sub_a = create(:web_push_subscription, user: user, endpoint: "https://push-a.test/ep")
    sub_b = create(:web_push_subscription, user: user, endpoint: "https://push-b.test/ep")

    described_class.call(user: user, user_habit: habit, web_push: push_client)

    expect(push_client).to have_received(:payload_send).with(
      message: message,
      endpoint: sub_a.endpoint,
      p256dh: sub_a.p256dh,
      auth: sub_a.auth,
      vapid: vapid_hash
    )

    expect(push_client).to have_received(:payload_send).with(
      message: message,
      endpoint: sub_b.endpoint,
      p256dh: sub_b.p256dh,
      auth: sub_b.auth,
      vapid: vapid_hash
    )
  end

  # [REQ-HAB-013]
  it "does not call the push client when there are no subscriptions" do
    described_class.call(user: user, user_habit: habit, web_push: push_client)

    expect(push_client).not_to have_received(:payload_send)
  end

  # [REQ-HAB-013]
  it "returns without sending when reminder_web_push is disabled" do
    habit.update!(reminder_email: true, reminder_web_push: false)
    create(:web_push_subscription, user: user)

    described_class.call(user: user, user_habit: habit.reload, web_push: push_client)

    expect(push_client).not_to have_received(:payload_send)
  end

  # [REQ-HAB-013]
  it "destroys a subscription when the push service reports it as expired" do
    sub_dead = create(:web_push_subscription, user: user, endpoint: "https://expired.test/ep")
    sub_live = create(:web_push_subscription, user: user, endpoint: "https://ok-expired.test/ep")
    response = instance_double(Net::HTTPResponse, body: "")

    allow(push_client).to receive(:payload_send) do |**kwargs|
      if kwargs[:endpoint] == sub_dead.endpoint
        raise WebPush::ExpiredSubscription.new(response, "push.test")
      end
    end

    expect {
      described_class.call(user: user, user_habit: habit, web_push: push_client)
    }.to change { WebPushSubscription.exists?(sub_dead.id) }.from(true).to(false)

    expect(WebPushSubscription.exists?(sub_live.id)).to be(true)
    expect(push_client).to have_received(:payload_send).twice
  end

  # [REQ-HAB-013]
  it "destroys a subscription when the push service reports it as invalid" do
    sub_dead = create(:web_push_subscription, user: user, endpoint: "https://gone.test/ep")
    sub_live = create(:web_push_subscription, user: user, endpoint: "https://ok.test/ep")
    response = instance_double(Net::HTTPResponse, body: "")

    allow(push_client).to receive(:payload_send) do |**kwargs|
      if kwargs[:endpoint] == sub_dead.endpoint
        raise WebPush::InvalidSubscription.new(response, "push.test")
      end
    end

    expect {
      described_class.call(user: user, user_habit: habit, web_push: push_client)
    }.to change { WebPushSubscription.exists?(sub_dead.id) }.from(true).to(false)

    expect(WebPushSubscription.exists?(sub_live.id)).to be(true)
    expect(push_client).to have_received(:payload_send).twice
  end

  # [REQ-HAB-013]
  it "logs and continues when one subscription raises an unexpected error" do
    sub_err = create(:web_push_subscription, user: user, endpoint: "https://err.test/ep")
    sub_ok = create(:web_push_subscription, user: user, endpoint: "https://after-err.test/ep")
    allow(push_client).to receive(:payload_send) do |**kwargs|
      raise StandardError, "timeout" if kwargs[:endpoint] == sub_err.endpoint
    end
    allow(Rails.logger).to receive(:warn)

    described_class.call(user: user, user_habit: habit, web_push: push_client)

    expect(push_client).to have_received(:payload_send).twice
    expect(Rails.logger).to have_received(:warn).with(
      a_string_matching(/DeliverHabitReminderWebPush.*subscription id=#{sub_err.id}/)
    )
  end
end
