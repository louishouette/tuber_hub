class UserPolicy < ApplicationPolicy
  # Policy for Hub::Admin::User
  def index?
    false # Restrict access since role concept is removed
  end

  def show?
    record == user # Users can only see their own profile
  end

  def create?
    false # Restrict access since role concept is removed
  end

  def update?
    record == user # Users can only update their own profile
  end

  def destroy?
    false # Restrict access since role concept is removed
  end

  class Scope < Scope
    def resolve
      scope.where(id: user.id) # Users can only access their own records
    end
  end
end
