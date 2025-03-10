class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      session = Session.create!(user: user, user_agent: request.user_agent, ip_address: request.remote_ip)
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true }
      Current.session = session
      
      if user.requires_password_change?
        redirect_to edit_password_path, notice: "Pour des raisons de sécurité, vous devez changer votre mot de passe."
      else
        redirect_to root_path
      end
    else
      redirect_to new_session_path, alert: "Invalid email or password"
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_id)
    redirect_to new_session_path
  end
end
