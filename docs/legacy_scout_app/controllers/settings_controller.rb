class SettingsController < ApplicationController
  def edit
    @user = Current.user
    @dogs = Dog.all
  end

  def update
    @user = Current.user

    if @user.update({ settings: settings_params })
      flash[:notice] = "Settings updated successfully."
      redirect_to edit_settings_path
    else
      @dogs = Dog.all
      flash.now[:alert] = "Failed to update settings. Please try again."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.expect(settings: [:default_dog]).to_h
  end
end