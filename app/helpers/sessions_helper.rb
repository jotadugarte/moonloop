# frozen_string_literal: true

module SessionsHelper
  USER_AGENT_BROWSER_RULES = [
    [ "Edg/", "Edge" ],
    [ "Firefox/", "Firefox" ],
    [ "Chrome/", "Chrome" ],
    [ "Version/", "Safari" ]
  ].freeze

  USER_AGENT_PLATFORM_RULES = [
    [ "Android", "Android" ],
    [ "iPhone", "iOS" ],
    [ "iPad", "iOS" ],
    [ "Windows", "Windows" ],
    [ "Mac OS X", "macOS" ],
    [ "Linux", "Linux" ]
  ].freeze

  def session_device_label(session)
    label = [ browser_label(session.user_agent.to_s), platform_label(session.user_agent.to_s) ].compact.join(" — ")
    label.presence || t("sessions.index.device_unknown")
  end

  def session_location_label(session)
    ip = session.ip_address.to_s
    return t("sessions.index.location_localhost") if localhost_ip?(ip)

    t("sessions.index.location_unavailable")
  end

  private

  def platform_label(user_agent)
    match_label(user_agent, USER_AGENT_PLATFORM_RULES)
  end

  def browser_label(user_agent)
    return nil if user_agent.include?("Chrome/") && user_agent.include?("Edg/")

    match_label(user_agent, USER_AGENT_BROWSER_RULES)
  end

  def match_label(user_agent, rules)
    rules.each { |needle, label| return label if user_agent.include?(needle) }
    nil
  end

  def localhost_ip?(ip)
    ip == "::1" || ip.start_with?("127.")
  end
end
