class ApplicationController < ActionController::API
  include Error::Handler
  include Transaction::Handler

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :null_session

  # ---- logging helpers ---------------------------------------------------

  def log_prefix(action, event, extra = {})
    base = "[UrlsController##{action}] #{event}"
    return base if extra.blank?

    "#{base} - #{extra.to_json}"
  end
end
