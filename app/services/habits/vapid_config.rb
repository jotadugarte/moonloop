# frozen_string_literal: true

module Habits
  # [REQ-HAB-013] VAPID keys and subject for WebPush.payload_send (mailto: or https: URL).
  class VapidConfig
    attr_reader :subject, :public_key, :private_key

    def initialize(subject:, public_key:, private_key:)
      @subject = subject
      @public_key = public_key
      @private_key = private_key
    end

    def self.from_application
      h = Rails.application.config.habit_web_push_vapid
      if Rails.env.production?
        %i[subject public_key private_key].each do |key|
          raise WebPush::ConfigurationError, "Missing habit Web Push VAPID #{key}" if h[key].blank?
        end
      end
      new(subject: h[:subject], public_key: h[:public_key], private_key: h[:private_key])
    end

    def to_web_push_hash
      { subject: subject, public_key: public_key, private_key: private_key }
    end
  end
end
