# TuberHub Notification System

This document explains how to use the notification system in TuberHub. The notification system provides real-time notifications to users using Rails 8's Solid Cable (Action Cable) for WebSockets.

## Overview

The notification system consists of several components:

1. **`Hub::Notification` model**: Stores notification data in the database
2. **`Hub::NotificationService`**: Service for creating and broadcasting notifications
3. **`Hub::Notifiable` concern**: Mixin for controllers to simplify notification creation
4. **`NotificationChannel`**: Action Cable channel for real-time notification delivery
5. **Stimulus controllers**: Frontend components for handling notification display

## Notification Types

The system supports the following notification types:

- `info`: General information (default)
- `success`: Positive outcomes, confirmations
- `warning`: Alerts that require attention but aren't critical
- `error`: Critical issues that need immediate attention

Each type has a corresponding CSS class and icon for consistent styling.

## Creating Notifications

### Using NotificationService Directly

```ruby
# Create a notification for a specific user
Hub::NotificationService.notify(
  user: current_user,
  message: "Your file has been processed",
  notification_type: :success,  # Optional, defaults to :info
  metadata: {                   # Optional, for storing additional data
    resource_type: "Document",
    resource_id: document.id
  },
  url: document_path(document)  # Optional, URL to redirect when clicked
)

# Create notifications for multiple users
users = Hub::Admin::User.where(role: "manager")
Hub::NotificationService.notify_all(
  users: users,
  message: "Team meeting starts in 15 minutes",
  notification_type: :info
)

# Create a notification and broadcast it immediately
# This is useful for real-time notifications
Hub::NotificationService.notify_and_broadcast(
  user: current_user,
  message: "New message received",
  notification_type: :info
)
```

### Using the Notifiable Concern

The `Hub::Notifiable` concern provides helper methods for controllers. Include it in your controller:

```ruby
class DocumentsController < ApplicationController
  include Hub::Notifiable
  
  def create
    @document = Document.new(document_params)
    
    if @document.save
      # Creates a flash notice and a notification with the same message
      notify :success, "Document was successfully created"
      redirect_to @document
    else
      render :new
    end
  end
  
  def update
    if @document.update(document_params)
      # Only creates a notification, no flash message
      notification :info, "Document was updated", url: document_path(@document)
      redirect_to @document
    else
      render :edit
    end
  end
  
  def destroy
    @document.destroy
    # Creates a notification with additional metadata
    notification :warning, "Document was deleted", metadata: { 
      resource_type: "Document", 
      resource_id: @document.id, 
      name: @document.name 
    }
    redirect_to documents_path
  end
end
```

## Displaying Notifications

### Notification Dropdown

To add the notification dropdown to your layout, include this in your application layout:

```erb
<%= render 'layouts/notification_dropdown' %>
```

### Toast Notifications

To enable toast notifications that appear temporarily at the top-right of the screen, add this to your application layout:

```erb
<%= render 'layouts/toast_container' %>
```

## Customizing Appearance

The notification system uses Flowbite and Tailwind CSS for styling. The appearance can be customized by modifying the following helper methods in `Hub::NotificationHelper`:

- `notification_css_class(notification_type)` - Returns CSS classes for a notification type
- `notification_icon(notification_type)` - Returns the icon for a notification type

## Notification Lifecycle

1. **Creation**: Notification is created via `NotificationService`
2. **Broadcasting**: Notification is broadcast to the user's channel if real-time
3. **Display**: 
   - Visible in the notification dropdown
   - Shown as a toast if it's new (not yet seen)
4. **Read**: Marked as read when viewed in detail
5. **Dismissal**: Removed from the list when dismissed

## Working with the JavaScript API

The notification system provides several custom events that you can listen for in your JavaScript code:

- `notification:received` - Fired when a new notification is received via WebSockets
- `notification:toast` - Fired when a toast notification should be displayed

Example:

```javascript
document.addEventListener('notification:received', (event) => {
  console.log('New notification:', event.detail)
})
```

## Backend API Endpoints

The notification system exposes the following API endpoints:

- `GET /hub/notifications` - List all notifications (paginated)
- `GET /hub/notifications/count` - Get the unread notification count
- `GET /hub/notifications/items` - Get notification items for the dropdown
- `GET /hub/notifications/unread` - Get all unread notifications
- `PATCH /hub/notifications/:id/read` - Mark a notification as read
- `PATCH /hub/notifications/:id/dismiss` - Dismiss a notification
- `PATCH /hub/notifications/:id/displayed` - Mark a notification as displayed
- `PATCH /hub/notifications/mark_all_as_read` - Mark all notifications as read

## Best Practices

1. Keep notification messages concise and clear
2. Use appropriate notification types based on severity
3. Only use real-time notifications for time-sensitive information
4. Include relevant context in metadata for advanced use cases
5. Consider user preferences (some users may want to disable certain notifications)

## Example Integration with a Model

You can add notification capabilities to your model. For example, with a `Comment` model:

```ruby
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :author, class_name: 'Hub::Admin::User'
  
  after_create :notify_post_owner
  
  private
  
  def notify_post_owner
    return if post.user_id == author_id # Don't notify if commenting on own post
    
    Hub::NotificationService.notify_and_broadcast(
      user: post.user,
      message: "#{author.name} commented on your post",
      notification_type: :info,
      metadata: {
        resource_type: 'Comment',
        resource_id: id,
        post_id: post_id
      },
      url: post_path(post, anchor: "comment-#{id}")
    )
  end
end
```

## Debugging

To debug Action Cable connections, check the server logs or browser console. You can add additional logging in the `NotificationChannel` or Stimulus controllers as needed.

## Customizing Behavior

The notification system is designed to be extensible. You can customize behavior by:

1. Overriding methods in `Hub::NotificationService`
2. Extending the `Hub::Notification` model with additional scopes
3. Adding new notification types in `Hub::NotificationHelper`
4. Customizing the JavaScript controllers for specific behaviors
