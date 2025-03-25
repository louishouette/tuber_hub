# frozen_string_literal: true

class ApplicationPolicy
  include PermissionPolicyConcern
  
  attr_reader :user, :record

  # Initialize the policy with a user and record
  # If user is nil, automatically use Current.user if available
  def initialize(user, record)
    @user = user || (defined?(Current) ? Current.user : nil)
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user || (defined?(Current) ? Current.user : nil)
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
