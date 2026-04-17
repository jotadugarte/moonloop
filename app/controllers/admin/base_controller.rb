require "set"

module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      return if current_user_admin?

      head :forbidden
    end

    def current_user_admin?
      return false if Current.user.blank?

      admin_emails.include?(Current.user.email.to_s.strip.downcase)
    end

    def admin_emails
      raw = ENV.fetch("MOONLOOP_ADMIN_EMAILS", "")
      raw.split(/[\s,;]+/).map { |e| e.to_s.strip.downcase }.reject(&:blank?).to_set
    end
  end
end
