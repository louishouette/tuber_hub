# frozen_string_literal: true

module Hub
  module Measure
    # Base controller for the Measure namespace
    class BaseController < Hub::BaseController
      include NamespaceViewPath
      include FarmSelection
    end
  end
end
