# frozen_string_literal: true

class WebPushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, :p256dh, :auth, presence: true
  validates :endpoint, uniqueness: { scope: :user_id }
end

