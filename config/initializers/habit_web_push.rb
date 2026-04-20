# frozen_string_literal: true

# [REQ-HAB-013]
# VAPID material for Web Push (RFC 8030). Prefer Rails credentials under `web_push:` with
# `vapid_subject`, `vapid_public_key`, `vapid_private_key`; optional ENV:
# WEB_PUSH_VAPID_SUBJECT, WEB_PUSH_VAPID_PUBLIC_KEY, WEB_PUSH_VAPID_PRIVATE_KEY.
# In test, keys are generated at boot. In non-production, missing keys fall back to ephemeral
# keys so local dev can exercise delivery without committing secrets. Production fills missing
# values only via credentials/ENV; `Habits::VapidConfig.from_application` raises on send if any
# are blank.
Rails.application.config.habit_web_push_vapid =
  if Rails.env.test?
    key = WebPush.generate_key
    {
      subject: "mailto:test@example.test",
      public_key: key.public_key,
      private_key: key.private_key
    }
  else
    raw = Rails.application.credentials.dig(:web_push)
    raw = raw.is_a?(Hash) ? raw.stringify_keys : {}
    from_store = {
      subject: raw["vapid_subject"].presence || ENV["WEB_PUSH_VAPID_SUBJECT"],
      public_key: raw["vapid_public_key"].presence || ENV["WEB_PUSH_VAPID_PUBLIC_KEY"],
      private_key: raw["vapid_private_key"].presence || ENV["WEB_PUSH_VAPID_PRIVATE_KEY"]
    }

    if from_store.values.all?(&:present?) || Rails.env.production?
      from_store
    else
      key = WebPush.generate_key
      {
        subject: from_store[:subject].presence || "mailto:dev@localhost",
        public_key: from_store[:public_key].presence || key.public_key,
        private_key: from_store[:private_key].presence || key.private_key
      }
    end
  end
