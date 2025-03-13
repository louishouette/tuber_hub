# frozen_string_literal: true

# This policy handles authorization for controllers based on namespace, controller, and action
# It replaces the custom authorization logic in Hub::BaseController
class NamespacePolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record # record should be a hash with namespace, controller, action keys
  end

  # Standard CRUD action methods following Pundit conventions
  def index?
    permission_check
  end
  
  def show?
    permission_check
  end
  
  def create?
    permission_check
  end
  
  def new?
    create?
  end
  
  def update?
    permission_check
  end
  
  def edit?
    update?
  end
  
  def destroy?
    permission_check
  end

  # Legacy method for backward compatibility
  # @deprecated Use standard Pundit action methods instead (index?, show?, etc.)
  def authorized?
    Rails.logger.warn "[DEPRECATION] NamespacePolicy#authorized? is deprecated. Use standard Pundit methods instead."
    permission_check(custom_action: record[:action])
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        # Default implementation - should be overridden in specific policies
        namespace = extract_namespace_from_scope
        controller = extract_controller_from_scope
        
        if namespace && controller && user&.can?('index', namespace, controller)
          scope.all
        else
          scope.none
        end
      end
    end
    
    private
    
    def extract_namespace_from_scope
      scope.name.underscore.split('/')[0..-2].join('/') if scope.respond_to?(:name)
    end
    
    def extract_controller_from_scope
      scope.table_name.split('_').last if scope.respond_to?(:table_name)
    end
  end
end
