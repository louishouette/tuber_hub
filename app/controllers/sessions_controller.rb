class SessionsController < ApplicationController
  layout "public/application"
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_url, alert: "Try again later." }
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def new
  end

  def create
    if user = Hub::Admin::User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to login_url, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to login_url
  end
end
