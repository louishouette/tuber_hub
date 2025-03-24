# frozen_string_literal: true

# Concern for setting default view paths for namespaced controllers
module NamespaceViewPath
  extend ActiveSupport::Concern

  included do
    before_action :set_default_namespace_view_path
  end

  private

  # Sets the default view path based on the controller's namespace
  # This allows views to be organized by namespace
  def set_default_namespace_view_path
    # Extract namespace from controller path (e.g., "hub/admin")
    namespace_path = self.class.controller_path.split('/')[0..-2].join('/')
    
    # Only set if we have a namespace
    if namespace_path.present?
      prepend_view_path "app/views/#{namespace_path}"
    end
  end
 end
