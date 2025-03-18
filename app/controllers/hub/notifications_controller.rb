module Hub
  # Handles user notifications including listing, marking as read, and dismissing
  #
  # This controller manages the notification center functionality and provides
  # both HTML and JSON endpoints for the notification UI components.
  class NotificationsController < HubController
    include Hub::Notifiable
    
    # All notification operations are scoped to the current user
    # Skip authorization checks for the index and related notification actions
    # since we're handling authorization through the policy_scope
    skip_after_action :verify_authorized, only: [:index, :items, :unread, :count, :read, :dismiss, :displayed, :toast, :mark_all_as_read, :empty_state]
    skip_after_action :verify_policy_scoped, only: [:items, :unread, :empty_state]
    
    before_action :set_notification, only: [:read, :dismiss, :displayed, :toast]
    
    # GET /hub/notifications
    # Displays the notification center with unread notifications
    def index
      @notifications = policy_scope(Hub::Notification).unread.recent.limit(15)
      @unread_count = policy_scope(Hub::Notification).unread.count
    end
    
    # POST /hub/notifications
    # Creates a new notification for the given user (admin only)
    def create
      authorize :hub_notification, :create?
      
      # Validate required parameters
      user_id = params[:user_id]
      message = params[:message]
      notification_type = params[:notification_type] || 'info'
      
      if user_id.blank? || message.blank?
        respond_to do |format|
          format.html { redirect_to hub_notifications_path, alert: 'User ID and message are required.' }
          format.json { render json: { error: 'User ID and message are required' }, status: :unprocessable_entity }
        end
        return
      end
      
      begin
        user = Hub::Admin::User.find(user_id)
        notification = Hub::NotificationService.notify_and_broadcast(
          user: user,
          message: message,
          notification_type: notification_type,
          url: params[:url]
        )
      rescue ActiveRecord::RecordNotFound
        respond_to do |format|
          format.html { redirect_to hub_notifications_path, alert: 'User not found.' }
          format.json { render json: { error: 'User not found' }, status: :not_found }
        end
        return
      end
      
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, notice: 'Notification was successfully sent.' }
        format.json { render json: notification, status: :created }
      end
    end
    
    # GET /hub/notifications/items
    # Returns HTML for the notification items (used for AJAX updates)
    def items
      @notifications = policy_scope(Hub::Notification).unread.recent.limit(15)
      render partial: "hub/notifications/items", locals: { notifications: @notifications }
    end
    
    # GET /hub/notifications/unread
    # Returns JSON of unread notifications for displaying toasts
    def unread
      @notifications = policy_scope(Hub::Notification).unread.not_displayed.recent.limit(5)
      render json: @notifications
    end
    
    # GET /hub/notifications/count
    # Returns unread notification count
    def count
      unread_count = policy_scope(Hub::Notification).unread.count
      
      respond_to do |format|
        format.html { render plain: unread_count.to_s }
        format.json { 
          render json: { 
            count: unread_count # For backward compatibility
          } 
        }
      end
    end
    
    # PATCH /hub/notifications/:id/read
    # Marks a notification as read
    def read
      @notification.mark_as_read!
      head :no_content
    end
    
    # PATCH /hub/notifications/:id/dismiss
    # Dismisses a notification so it no longer appears in the list
    def dismiss
      @notification.dismiss!
      head :no_content
    end
    
    # PATCH /hub/notifications/:id/displayed
    # Marks a notification as displayed (shown as a toast)
    def displayed
      @notification.mark_as_displayed!
      head :no_content
    end
    
    # GET /hub/notifications/:id/toast
    # Returns HTML for a toast notification
    def toast
      render partial: "hub/notifications/toast", locals: { notification: @notification }
    end
    
    # POST /hub/notifications/mark_all_as_read
    # Marks all notifications as read for the current user
    def mark_all_as_read
      # Get a count of affected notifications for reporting
      unread_count = policy_scope(Hub::Notification).unread.count
      
      # Mark all as read
      policy_scope(Hub::Notification).unread.update_all(read_at: Time.zone.now)
      
      # Broadcast the change via Action Cable
      if defined?(Hub::NotificationChannel)
        Hub::NotificationChannel.broadcast_to(
          Current.user,
          { type: 'all_notifications_read', count: 0, timestamp: Time.zone.now.to_i }
        )
      end
      
      # Invalidate cache
      Rails.cache.delete("user_#{Current.user.id}_unread_count")
      
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, notice: 'All notifications marked as read.' }
        format.json { render json: { success: true, count: 0, message: 'All notifications marked as read' } }
      end
    end
    
    # GET /hub/notifications/empty_state
    # Returns the empty state partial for when there are no notifications
    def empty_state
      render partial: "hub/notifications/empty_state", layout: false
    end
    
    private
    
    # Sets @notification from the current user's notifications
    # @raise [ActiveRecord::RecordNotFound] if notification doesn't exist or doesn't belong to current user
    def set_notification
      if params[:id].blank?
        respond_to do |format|
          format.html { redirect_to hub_notifications_path, alert: 'Notification ID is required.' }
          format.json { render json: { error: 'Notification ID is required' }, status: :unprocessable_entity }
          format.js { head :unprocessable_entity }
        end
        return
      end
      
      @notification = policy_scope(Hub::Notification).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, alert: 'Notification not found.' }
        format.json { render json: { error: 'Notification not found' }, status: :not_found }
        format.js { head :not_found }
      end
    end
  end
end
