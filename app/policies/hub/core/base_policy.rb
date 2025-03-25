# frozen_string_literal: true

module Hub
  module Core
    # Base policy for the Core namespace
    class BasePolicy < ApplicationPolicy
      include PermissionPolicyConcern
    end
  end
end
