# frozen_string_literal: true

module Habits
  # [REQ-HAB-013] JSON body encrypted by the web-push gem for display in the service worker.
  class WebPushNotificationPayload
    attr_reader :title, :body, :tag

    def initialize(title:, body:, tag: nil)
      @title = title
      @body = body
      @tag = tag
    end

    def self.from_user_habit(user_habit)
      new(
        title: I18n.t("habit_reminder_web_push.notify.title", habit_name: user_habit.name),
        body: I18n.t("habit_reminder_web_push.notify.body", habit_name: user_habit.name),
        tag: "habit-reminder-#{user_habit.id}"
      )
    end

    def to_message_string
      JSON.generate({ title: title, body: body, tag: tag }.compact)
    end
  end
end
