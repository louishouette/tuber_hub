# frozen_string_literal: true

module Hub
  module Cultivation
    # Base policy for the Cultivation namespace
    class BasePolicy < ApplicationPolicy
      include PermissionPolicyConcern
    end
  end
end
