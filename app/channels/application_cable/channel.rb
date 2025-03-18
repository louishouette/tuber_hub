module ApplicationCable
  class Channel < ActionCable::Channel::Base
    before_subscribe :set_current_user
    
    private
      # Set Current.user from the connection's identified_by current_user
      # This ensures that Current.user is available in channel methods
      def set_current_user
        # We can't directly set Current.user as it's delegated to session
        # Instead, we need to create a session-like object with a user method
        if connection.current_user
          Current.session = SessionProxy.new(connection.current_user)
        end
      end
      
      # Simple proxy class that mimics a session with a user method
      class SessionProxy
        attr_reader :user
        
        def initialize(user)
          @user = user
        end
      end
  end
end
