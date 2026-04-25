class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale
  before_action :set_current_request_details
  before_action :authenticate

  private
    def switch_locale(&)
      requested = params[:locale].presence&.to_sym
      locale = I18n.available_locales.include?(requested) ? requested : I18n.locale
      I18n.with_locale(locale, &)
    end

    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        redirect_to sign_in_path
      end
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end
