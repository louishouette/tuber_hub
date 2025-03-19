# frozen_string_literal: true

module Hub
  module Core
    class BaseController < Hub::BaseController
      before_action :set_default_view_path
      
      private
      
      # Set the default view path to include the namespace
      def set_default_view_path
        prepend_view_path Rails.root.join('app', 'views', 'hub', 'core')
      end
    end
  end
end
