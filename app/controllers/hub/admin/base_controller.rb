# frozen_string_literal: true

module Hub
  module Admin
    # Base controller for the Admin namespace
    class BaseController < Hub::BaseController
      include NamespaceViewPath
      include AdminAuthorization
    end
  end
end
