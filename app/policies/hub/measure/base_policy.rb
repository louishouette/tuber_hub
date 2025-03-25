# frozen_string_literal: true

module Hub
  module Measure
    # Base policy for the Measure namespace
    class BasePolicy < ApplicationPolicy
      include PermissionPolicyConcern
    end
  end
end
