# frozen_string_literal: true

# This policy handles authorization for admin-specific controllers and actions
# It replaces the custom admin authorization logic in Hub::Admin::BaseController
class AdminPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record # Symbol or specific admin resource
  end

  # Standard CRUD action methods following Pundit conventions
  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def new?
    create?
  end

  def update?
    user&.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  # Method to authorize viewing users for a role
  def users?
    user&.admin?
  end

  # Legacy method for backward compatibility
  # @deprecated Use standard Pundit action methods instead (index?, show?, etc.)
  def access?
    Rails.logger.warn "[DEPRECATION] AdminPolicy#access? is deprecated. Use standard Pundit methods instead."
    user&.admin?
  end
  
  # Method to authorize assigning roles to users
  def assign_roles?
    user&.admin?
  end
  
  # Method to authorize assigning permissions to roles
  def assign_permissions?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
