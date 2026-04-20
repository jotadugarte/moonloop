# frozen_string_literal: true

module Habits
  # [REQ-HAB-013] Best-effort Web Push per stored subscription; removes dead subscriptions (404/410).
  class DeliverHabitReminderWebPush
    SUBSCRIPTION_BATCH_SIZE = 500

    def self.call(user:, user_habit:, web_push: WebPush)
      new(user: user, user_habit: user_habit, web_push: web_push).call
    end

    def initialize(user:, user_habit:, web_push: WebPush)
      @user = user
      @user_habit = user_habit
      @web_push = web_push
    end

    def call
      return unless @user_habit.reminder_web_push?

      vapid = Habits::VapidConfig.from_application.to_web_push_hash
      message = Habits::WebPushNotificationPayload.from_user_habit(@user_habit).to_message_string

      @user.web_push_subscriptions.find_each(batch_size: SUBSCRIPTION_BATCH_SIZE) do |sub|
        deliver_one(sub, message, vapid)
      end

      :ok
    end

    private

    def deliver_one(subscription, message, vapid)
      @web_push.payload_send(
        message: message,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: vapid
      )
    rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
      subscription.destroy!
    end
  end
end
