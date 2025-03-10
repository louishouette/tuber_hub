class PasswordsController < ApplicationController
  skip_before_action :require_authentication, if: -> { Current.user&.first_login? }
  
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    # Update both password and first_login setting
    if @user.update(password_params) && @user.update(settings: @user.settings.merge("first_login" => false))
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def password_params
      params.expect(user: [:password, :password_confirmation])
    end
end
