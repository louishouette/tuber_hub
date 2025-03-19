module ApplicationHelper
  # Generate initials from a user's name
  # @param name [String] the full name
  # @return [String] the initials
  def user_initials(name)
    return "" if name.blank?
    
    name.split.map(&:first).join
  end
  
  # Consumes the flash messages so they aren't displayed twice
  # This method should be called in the application layout
  # after rendering the flash messages
  def consume_flash
    # Store the flash in a local variable
    stored_flash = flash.to_hash
    # Clear the flash
    flash.clear
    # Return the stored flash in case we need it
    stored_flash
  end
end
