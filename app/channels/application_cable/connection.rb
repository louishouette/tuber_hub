module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        # First try to find user from session
        if session = find_session_by_cookie
          session.user
        # For testing, fall back to the first user in the system
        elsif verified_user = Hub::Admin::User.first
          verified_user
        else
          reject_unauthorized_connection
        end
      end
      
      def find_session_by_cookie
        Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      end
  end
end
