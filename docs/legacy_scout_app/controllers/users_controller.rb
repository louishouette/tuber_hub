class UsersController < ApplicationController
  before_action :require_admin, only: [:index, :update]
  before_action :require_can_create_users, only: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: [:email_address, :first_name, :last_name, :role, :is_active, :can_survey, :can_harvest])
    end

    def require_admin
      unless Current.user&.can_manage_users?
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    end

    def require_can_create_users
      unless Current.user&.can_create_users?
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    end
end
