# frozen_string_literal: true

module Hub
  # Policy for Hub::Admin namespace
  class AdminPolicy < ApplicationPolicy
    def index?
      Current.user.admin?
    end

    def show?
      Current.user.admin?
    end

    def create?
      Current.user.admin?
    end

    def update?
      Current.user.admin?
    end

    def destroy?
      Current.user.admin?
    end

    class Scope < Scope
      def resolve
        Current.user.admin? ? scope.all : scope.none
      end
    end
  end
end
