# frozen_string_literal: true

module Hub
  module Core
    # Base controller for the Core namespace
    class BaseController < Hub::BaseController
      include NamespaceViewPath
      include FarmSelection
    end
  end
end
