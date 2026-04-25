# frozen_string_literal: true

module SessionsHelper
  def session_device_label(session)
    parsed = UserAgent.parse(session.user_agent.to_s)
    [ parsed.browser, parsed.platform ].compact.join(" — ").presence || t("sessions.index.device_unknown")
  end

  def session_location_label(session)
    ip = session.ip_address.to_s
    return t("sessions.index.location_localhost") if localhost_ip?(ip)

    t("sessions.index.location_unavailable")
  end

  private

  def localhost_ip?(ip)
    ip == "::1" || ip.start_with?("127.")
  end
end

