module ApplicationHelper
  # Generate initials from a user's name
  # @param name [String] the full name
  # @return [String] the initials
  def user_initials(name)
    return "" if name.blank?
    
    name.split.map(&:first).join
  end
end
