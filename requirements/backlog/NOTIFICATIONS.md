Based on the codebase search, I can explain the key differences between flash messages and notifications:

Flash Messages:
Are temporary messages that appear only for the current request/response cycle
Are typically used to show the result of an action (success/error/info)
Examples:
"Profile successfully updated"
"Error: Invalid email format"
"Your changes have been saved"
Are managed by Rails' built-in flash system
Auto-disappear after a short time
Are more transient in nature
Notifications:
Are persistent messages stored in the database (though I don't see a notification model yet in your app)
Stay visible until the user interacts with them
Are used for longer-term or important information
Examples:
"New harvesting run completed"
"Someone mentioned you in a comment"
"Your report is ready to download"
Would typically have their own model and database table
Need to be explicitly marked as read
Are more permanent in nature
Currently in your app:

Flash messages are fully implemented using Rails' flash system
The notifications system appears to be a placeholder (showing "No notifications") and might be implemented in the future
Both are displayed in the same dropdown for a unified user experience, but they serve different purposes
Would you like me to help you implement a proper notifications system for persistent notifications?