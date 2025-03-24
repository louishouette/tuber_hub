# frozen_string_literal: true

module Hub
  # Policy for Hub::Admin namespace
  class AdminPolicy < ApplicationPolicy
    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def create?
      user.admin?
    end

    def update?
      user.admin?
    end

    def destroy?
      user.admin?
    end

    class Scope < Scope
      def resolve
        user.admin? ? scope.all : scope.none
      end
    end
  end
end
