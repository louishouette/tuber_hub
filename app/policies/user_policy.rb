class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin? || user.moderator? || record == user
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || record == user
  end

  def destroy?
    user.admin? && record != user
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.moderator?
        scope.where.not(role: 'admin')
      else
        scope.where(id: user.id)
      end
    end
  end
end
