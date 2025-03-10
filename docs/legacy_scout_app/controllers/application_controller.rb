class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern, strict: false
  
  # Breadcrumbs functionality removed as it is no longer needed
  
  before_action :set_locale
  
  private
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  
  def default_url_options
    { locale: I18n.locale }
  end
end
