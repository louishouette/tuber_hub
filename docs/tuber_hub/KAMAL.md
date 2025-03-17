# Deploying Tuber Hub With Kamal 2

## Overview

This guide explains how to deploy Tuber Hub application using Kamal 2 with Thruster for zero-downtime deployments, with a particular focus on configuring Solid Cable for real-time notifications. We'll use PostgreSQL for both the database and as a pub/sub backend for Action Cable.

## Prerequisites

- A Rails 8 application (Tuber Hub)
- Docker installed locally
- A PostgreSQL server
- One or more production servers with Docker installed
- SSH access to the production servers

## Initial Kamal Setup

1. Add Kamal to your Gemfile and install it:

```ruby
# In your Gemfile
gem "kamal", "~> 2.0"
```

```bash
bundle install
```

2. Initialize Kamal in your project:

```bash
bin/kamal init
```

3. This will create a `config/deploy.yml` file that you'll need to customize.

## Configuring Kamal for PostgreSQL and Solid Cable

Edit your `config/deploy.yml` file to include PostgreSQL and Solid Cable configurations:

```yaml
# config/deploy.yml
service: tuber-hub

image: your-docker-hub-username/tuber-hub

registry:
  username: your-docker-hub-username
  password: <%= ENV["DOCKER_HUB_PASSWORD"] %>

servers:
  web:
    hosts:
      - user@your-app-server-ip
    cmd: bundle exec puma -C config/puma.rb
    env:
      RAILS_ENV: production
      RAILS_MASTER_KEY: <%= ENV["RAILS_MASTER_KEY"] %>
      DATABASE_URL: <%= ENV["DATABASE_URL"] %>
      REDIS_URL: <%= ENV["REDIS_URL"] %>
      CABLE_URL: <%= ENV["CABLE_URL"] %>

  cable:
    hosts:
      - user@your-app-server-ip  # Can be the same as web or separate
    cmd: bundle exec solid_cable
    env:
      RAILS_ENV: production
      RAILS_MASTER_KEY: <%= ENV["RAILS_MASTER_KEY"] %>
      DATABASE_URL: <%= ENV["DATABASE_URL"] %>
      CABLE_URL: <%= ENV["CABLE_URL"] %>

thruster:
  # Enable Thruster for zero-downtime deployments
  enabled: true
  
  # Health check path for your application
  health_check_path: /up
  
  # Health check interval in seconds
  health_check_interval: 5
  
  # Maximum time to wait for health check to pass in seconds
  health_check_timeout: 60
  
  # Time to wait between stopping old container and starting new one
  transition_wait: 2
```

## Configuring Action Cable (Solid Cable) with PostgreSQL

1. Make sure you have Solid Cable installed in your application:

```bash
bin/rails solid_cable:install
```

2. Configure your database.yml to include a dedicated connection for cable:

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: tuber_hub_development
  username: your_postgres_username
  password: your_postgres_password

test:
  <<: *default
  database: tuber_hub_test

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

3. Configure your cable.yml to use PostgreSQL:

```yaml
# config/cable.yml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: postgresql
  url: <%= ENV.fetch("CABLE_URL") { ENV["DATABASE_URL"] } %>
  channel_prefix: tuber_hub_production
```

4. Set up the required environment variables in your production environment:

```
DATABASE_URL=postgres://username:password@postgres-host:5432/tuber_hub_production
CABLE_URL=postgres://username:password@postgres-host:5432/tuber_hub_production
```

## Setting Up NGINX for WebSocket Support

Create a custom Kamal accessory for NGINX with WebSocket support:

```yaml
# config/deploy/accessories/nginx.yml
name: nginx

image: nginx:1.25-alpine

roles:
  - web
  - cable

publish:
  - "80:80"
  - "443:443"

volumes:
  - "/etc/nginx/conf.d:/etc/nginx/conf.d"
  - "/etc/letsencrypt:/etc/letsencrypt"
  - "/var/www/html:/var/www/html"

accessories:
  certbot:
    image: certbot/certbot
    roles: [web]
    volumes:
      - "/etc/letsencrypt:/etc/letsencrypt"
      - "/var/www/html:/var/www/html"
    cmd: renew
```

Create a custom NGINX configuration that supports WebSockets:

```
# config/deploy/accessories/nginx/conf.d/default.conf
upstream app {
  server ${SERVICE_APP}:3000;
}

upstream cable {
  server ${SERVICE_CABLE}:28080;
}

server {
  listen 80;
  server_name your-domain.com;

  location /.well-known/acme-challenge/ {
    root /var/www/html;
  }

  location / {
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 ssl;
  server_name your-domain.com;

  ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

  # Web application
  location / {
    proxy_pass http://app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # WebSocket for Action Cable
  location /cable {
    proxy_pass http://cable;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

## JavaScript Client Configuration

Update your JavaScript to connect to the Action Cable server:

```javascript
// app/javascript/application.js
import { createConsumer } from "@rails/actioncable"

// In production, WebSocket requests go to /cable path on the same domain
// In development, connect directly to the development server
const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
const wsHost = process.env.NODE_ENV === 'production' ? window.location.host : 'localhost:3000'
const wsPath = '/cable'

const consumer = createConsumer(`${wsProtocol}//${wsHost}${wsPath}`)

// Export the consumer for use in other modules
export default consumer
```

## Deployment

1. Build and push your Docker image:

```bash
bin/kamal build
```

2. Deploy your application:

```bash
bin/kamal deploy
```

3. To set up the database on the first deployment:

```bash
bin/kamal exec web "bundle exec rails db:prepare"
```

## Managing Solid Cable in Production

### Scaling

To scale the number of cable servers:

```bash
bin/kamal scale cable=2
```

### Viewing Logs

To view logs from the cable servers:

```bash
bin/kamal logs cable
```

### Troubleshooting

If you're having issues with WebSocket connections:

1. Check your NGINX configuration to ensure WebSocket support is properly configured
2. Verify that the cable service is running: `bin/kamal status`
3. Check the cable logs for any errors: `bin/kamal logs cable`
4. Ensure your firewall allows WebSocket connections on port 443

## Maintenance

### Backing Up PostgreSQL Database

Create a backup script on your database server:

```bash
#!/bin/bash
DATABASE="tuber_hub_production"
USERNAME="postgres"
BACKUP_DIR="/path/to/backups"
FILENAME="tuber_hub_$(date +%Y%m%d_%H%M%S).sql"

pg_dump -U $USERNAME $DATABASE > "$BACKUP_DIR/$FILENAME"
gzip "$BACKUP_DIR/$FILENAME"
```

### Monitoring Connection Status

To check the current WebSocket connections status in production:

```bash
bin/kamal exec cable "bundle exec rails runner 'puts ActiveCable::Server.connections.count'"
```

## Conclusion

You now have a fully configured Tuber Hub application deployed with Kamal 2, using Thruster for zero-downtime deployments and Solid Cable with PostgreSQL as the pub/sub backend for real-time notifications.

For more information, refer to:
- [Kamal 2 Documentation](https://kamal-deploy.org)
- [Rails 8 Solid Cable Documentation](https://edgeguides.rubyonrails.org/solid_cable.html)
- [Notification System Documentation](docs/NOTIFICATIONS.md)
