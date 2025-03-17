# TuberHub Authentication System Documentation

## Overview

TuberHub uses a session-based authentication system built on Rails 8 best practices and aligned with the new Rails 8 authentication generator. The system provides secure login/logout functionality, session management, and protection for routes that require authenticated access.

## Key Components

### 1. Models

- **Hub::Admin::User**: The central user model with authentication capabilities.
- **Session**: Represents a user session with browser and IP information.

### 2. Controllers

- **SessionsController**: Manages user login, logout, and session creation.
- **PasswordsController**: Handles password reset functionality.

### 3. Concerns

- **Authentication**: A controller concern providing authentication helpers.

## Authentication Flow

### Login Process

1. User visits the login page (`/login`).
2. User submits their email address and password.
3. The system authenticates the user via `Hub::Admin::User.authenticate_by`.
4. If successful, a new session is created with:
   - User agent information
   - IP address
   - Session token
5. The session ID is stored in a secure, HTTP-only cookie.
6. User is redirected to their intended destination or the root path.

### Session Management

The system manages user sessions with a `Current` object pattern:

1. On each request, the `Authentication` concern attempts to resume an existing session.
2. It looks for a valid session ID in the cookies.
3. If found, it sets `Current.session` and `Current.user` for the request duration.
4. If not found or invalid, unauthenticated users are redirected to the login page.

### Logout Process

1. User initiates logout by clicking a logout link (sends DELETE request to `/logout`).
2. The current session is terminated and removed from the database.
3. The session cookie is cleared from the browser.
4. User is redirected to the login page.

## Authentication Protection

### Route Protection

By default, all controllers require authentication. Controllers must explicitly opt-out by using:

```ruby
allow_unauthenticated_access only: [:index, :show]
```

This is typically used for:
- Public pages
- The login page itself
- Password reset functionality

### Rate Limiting

The login endpoint is rate-limited to prevent brute force attacks:

```ruby
rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_url, alert: "Try again later." }
```

## Security Features

### Password Security

- Passwords are hashed using Rails' `has_secure_password` with bcrypt.
- Password resets use secure, time-limited tokens.

### Session Security

- Session IDs are stored in secure, HTTP-only cookies.
- Session cookies use the `same_site: :lax` setting to prevent CSRF attacks.
- User agent and IP address are recorded for audit purposes.

### User Account Security

- Users can be disabled by setting `active: false`.
- Login attempts track timestamps and counts for monitoring.

## Authentication-Related Helpers

### In Controllers

```ruby
# Check if user is authenticated
authenticated?

# Get current authenticated user
Current.user

# Start a new session for a user
start_new_session_for(user)

# End the current session
terminate_session
```

### In Views

```ruby
# Check if user is authenticated
authenticated?

# Access the current user
Current.user

# Get user full name
Current.user.full_name
```

## Rails 8 Authentication Alignment

TuberHub's authentication system follows the patterns introduced by the Rails 8 authentication generator, with customizations to fit our specific needs:

1. **Namespaced User Model**: Our user model is namespaced as `Hub::Admin::User` but maintains the same functionality as the Rails 8 generator's `User` model.

2. **Custom Routes**: We use `/login` and `/logout` routes instead of the default resource routes, providing a more intuitive user experience while maintaining the same security features.

3. **`Current` Thread Safety**: We use the same `Current` thread-safe object pattern introduced in Rails 8 to safely manage user state across requests.

4. **Authentication Method**: We implement the `authenticate_by` method on the User model following Rails 8's pattern.

5. **Session Management**: We use the same cookie-based secure session approach with HTTP-only flags and same-site protection.

## Best Practices

1. **Always check authentication status** before performing sensitive operations.
2. **Use the `Current` object** to access the authenticated user, not session variables directly.
3. **Implement proper logout** by calling `terminate_session` to ensure the session is properly destroyed.
4. **Set appropriate session timeouts** for security.
5. **Use HTTPS** in production to protect authentication cookies.

## Troubleshooting

### Common Issues

1. **User can't log in**:
   - Check if the user account is active
   - Verify email and password are correct
   - Check if rate limiting is active

2. **User is unexpectedly logged out**:
   - Session might have expired
   - Cookie might have been cleared
   - User might be accessing from a different browser

3. **Authentication check fails**:
   - Ensure `before_action :require_authentication` is not skipped
   - Check if the session cookie is properly set
   - Verify the session exists in the database

## Authentication-Related Database Schema

### Users Table (hub_admin_users)

- `email_address`: User's email (unique identifier)
- `password_digest`: Hashed password
- `active`: Whether the user account is active
- `last_sign_in_at`: When the user last signed in
- `sign_in_count`: Number of times the user has signed in
- `current_sign_in_ip`: IP address of the current session

### Sessions Table

- `user_id`: Reference to the user
- `ip_address`: IP address of the client
- `user_agent`: Browser/client information
- `created_at`: When the session started

## Conclusion

TuberHub's authentication system provides a secure, flexible approach to managing user identities and sessions. Built on Rails 8 conventions, it ensures that only authorized users can access protected resources while providing a smooth user experience.
