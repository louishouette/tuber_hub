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
    # Displays the notification center with recent notifications
    def index
      @notifications = policy_scope(Hub::Notification).undismissed.recent.limit(15)
      @unread_count = policy_scope(Hub::Notification).unread.count
      @total_count = policy_scope(Hub::Notification).count
      @read_rate = @total_count > 0 ? ((@total_count - @unread_count).to_f / @total_count * 100).round : 0
    end
    
    # POST /hub/notifications
    # Creates a new notification for the given user (admin only)
    def create
      authorize :hub_notification, :create?
      
      notification = Hub::NotificationService.notify_and_broadcast(
        user: Hub::Admin::User.find(params.expect(:user_id)),
        message: params.expect(:message),
        notification_type: params.expect(:notification_type, 'info'),
        url: params[:url]
      )
      
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, notice: 'Notification was successfully sent.' }
        format.json { render json: notification, status: :created }
      end
    end
    
    # GET /hub/notifications/items
    # Returns HTML for the notification items (used for AJAX updates)
    def items
      @notifications = policy_scope(Hub::Notification).undismissed.recent.limit(15)
      render partial: "hub/notifications/items", locals: { notifications: @notifications }
    end
    
    # GET /hub/notifications/unread
    # Returns JSON of unread notifications for displaying toasts
    def unread
      @notifications = policy_scope(Hub::Notification).not_displayed.recent.limit(5)
      render json: @notifications
    end
    
    # GET /hub/notifications/count
    # Returns the count of unread notifications
    def count
      count = policy_scope(Hub::Notification).unread.undismissed.count
      render json: { count: count }
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
      policy_scope(Hub::Notification).unread.update_all(read_at: Time.zone.now)
      
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, notice: 'All notifications marked as read.' }
        format.json { head :no_content }
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
      @notification = policy_scope(Hub::Notification).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to hub_notifications_path, alert: 'Notification not found.' }
        format.json { render json: { error: 'Notification not found' }, status: :not_found }
        format.js { head :not_found }
      end
    end
  end
end
