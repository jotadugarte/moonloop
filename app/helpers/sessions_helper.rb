# frozen_string_literal: true

module SessionsHelper
  USER_AGENT_BROWSER_RULES = [
    [ "Edg/", :edge ],
    [ "Firefox/", :firefox ],
    [ "Chrome/", :chrome ],
    [ "Version/", :safari ]
  ].freeze

  USER_AGENT_PLATFORM_RULES = [
    [ "Android", :android ],
    [ "iPhone", :ios ],
    [ "iPad", :ios ],
    [ "Windows", :windows ],
    [ "Mac OS X", :macos ],
    [ "Linux", :linux ]
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
    key = match_key(user_agent, USER_AGENT_PLATFORM_RULES)
    key.present? ? t("sessions.user_agent.platforms.#{key}") : nil
  end

  def browser_label(user_agent)
    return nil if user_agent.include?("Chrome/") && user_agent.include?("Edg/")

    key = match_key(user_agent, USER_AGENT_BROWSER_RULES)
    key.present? ? t("sessions.user_agent.browsers.#{key}") : nil
  end

  def match_key(user_agent, rules)
    rules.each { |needle, key| return key if user_agent.include?(needle) }
    nil
  end

  def localhost_ip?(ip)
    ip == "::1" || ip.start_with?("127.")
  end
end
