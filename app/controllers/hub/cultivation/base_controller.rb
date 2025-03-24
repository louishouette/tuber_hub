# frozen_string_literal: true

module Hub
  module Cultivation
    # Base controller for the Cultivation namespace
    class BaseController < Hub::BaseController
      include NamespaceViewPath
      include FarmSelection
    end
  end
end
