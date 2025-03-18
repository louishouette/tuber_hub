# TuberHub Notification System

A real-time notification system using Rails 8's Solid Cable technology for WebSockets.

## Key Components

### Server-Side

- **`Hub::Notification`**: Database model for notifications
- **`Hub::NotificationService`**: Creates and broadcasts notifications
- **`Hub::Notifiable`**: Controller mixin for easy notification creation
- **`Hub::NotificationChannel`**: Action Cable channel for real-time delivery

### Client-Side

- **Utilities**: `notification_utils.js`, `event_bus.js`, `notification_types.js`
- **Channel**: `notification_channel.js` (receives broadcasts)
- **Controllers**: Stimulus controllers for UI components
  - `notifications_controller.js`: Main container
  - `notification_counter_controller.js`: Count badge
  - `notification_list_controller.js`: List UI
  - `toast_controller.js`: Toast notifications

## Data Flow & Architecture

**Core Principles:**
- **Unidirectional Flow**: Server broadcasts → Client receives → UI updates
- **No Polling**: Only use Action Cable for real-time updates
- **Event-Driven**: Components communicate via event bus

**Notification Types:**
- `info`: General information (blue)
- `success`: Positive outcomes (green)
- `warning`: Alerts requiring attention (yellow)
- `error`: Critical issues (red)

## Usage

### Creating Notifications

```ruby
# Basic notification
Hub::NotificationService.notify(
  user: Current.user,
  message: "Your file has been processed",
  notification_type: :success  # :info, :success, :warning, :error
)

# With additional options
Hub::NotificationService.notify(
  user: Current.user,
  message: "Document updated",
  notification_type: :info,
  metadata: { resource_id: doc.id },
  url: document_path(doc)
)

# For multiple users
Hub::NotificationService.notify_all(
  users: User.admins,
  message: "System maintenance complete"
)

# Broadcast immediately (real-time)
Hub::NotificationService.notify_and_broadcast(
  user: Current.user,
  message: "New message received"
)
```

### In Controllers (using Notifiable concern)

```ruby
class DocumentsController < ApplicationController
  include Hub::Notifiable
  
  def create
    # Creates notification and flash message
    notify :success, "Document was created"
  end
  
  def update
    # Notification only, no flash
    notification :info, "Document was updated"
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

### Event System Architecture

The notification system uses a centralized event bus to avoid circular dependencies and ensure proper event flow. All components should communicate through this bus rather than directly with each other.

### Key Events

The notification system provides several custom events that you can listen for in your JavaScript code:

- `notification:received` - Fired when a new notification is received via WebSockets
- `notification:toast` - Fired when a toast notification should be displayed
- `notification:count-changed` - Fired when the notification count changes
- `notification:dismiss` - Fired when a notification is dismissed

### Event Handling Best Practices

1. **Prevent Event Loops**: When handling an event that might cause state changes, be careful not to trigger the same event again
2. **Use Data in Events**: Pass all necessary data in the event detail to avoid additional AJAX requests
3. **Separate UI Updates from Data Operations**: Keep DOM updates separate from data operations

Example:

```javascript
// GOOD: Uses the event bus and prevents loops
import notificationEventBus from "utilities/event_bus"

notificationEventBus.on('notification:count-changed', (data) => {
  // Just update the UI with the data provided in the event
  // No additional AJAX requests or event emissions
  this.updateBadge(data.count)
})

// BAD: Creates potential event loops
document.addEventListener('notification:count-changed', () => {
  // This will cause another AJAX request and potentially another event
  this.updateCount() 
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

1. **No Polling**: Never use polling or intervals when Action Cable is available
2. **Single Source of Truth**: All real-time updates should come through Action Cable
3. **Avoid Circular Events**: Be careful not to create event loops where events trigger handlers that emit the same events
4. **Component Independence**: UI components should only depend on the event bus, not directly on each other
5. **Keep notification messages concise and clear**
6. **Use appropriate notification types based on severity**
7. **Only use real-time notifications for time-sensitive information**
8. **Include relevant context in metadata for advanced use cases**
9. **Consider user preferences (some users may want to disable certain notifications)**

## Design Principles

- **Server Push Over Client Pull**: Always prefer Action Cable broadcasts over client-side polling
- **Unidirectional Data Flow**: Data flows in one direction: Server → Action Cable → Event Bus → UI Components
- **Separation of Concerns**: Logic separated into distinct modules
- **DRY (Don't Repeat Yourself)**: Common functionality extracted to utilities
- **Single Responsibility**: Each component has a clear purpose
- **Event-driven Architecture**: Components communicate through events
- **Responsive Design**: Mobile-first approach with responsive UI

## Style Guidelines

- Notification dropdown is responsive (fixed on mobile, absolute on desktop)
- Toast notifications appear in the top-right corner by default
- Smooth animations for all notification interactions
- Consistent color coding based on notification type

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

## Troubleshooting

### Common Issues
- **Infinite AJAX Loops**: Check for circular event handling
- **Missing Updates**: Verify Action Cable connections
- **Nil User Errors**: Check Current.user access in channels

### Debugging
1. Check browser console for connection status
2. Verify channel subscription (`Hub::NotificationChannel`)
3. Monitor server logs for broadcasts
4. Check network tab for excessive requests

## Recent Improvements

1. **Eliminated Polling** - Using pure Action Cable
2. **Fixed Event Handling** - Unidirectional data flow
3. **Enhanced Performance** - Solid Cache integration
4. **Better Error Handling** - Graceful degradation

See `/requirements/changelog/developping_notifications.md` for details.

## Future Roadmap

- Notification grouping and categorization
- User notification preferences
- Rich content support (images, formatting)
- Engagement metrics and analytics
- Cross-device synchronization
- Expiration and archiving features
