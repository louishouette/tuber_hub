# frozen_string_literal: true

module Hub
  module Admin
    # Base policy for the Admin namespace
    class BasePolicy < ApplicationPolicy
      include PermissionPolicyConcern
    end
  end
end
