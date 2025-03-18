# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "flowbite", to: "https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
# Action Cable setup
pin "@rails/actioncable", to: "actioncable.esm.js"

# Pin the channels through the index.js file
pin "channels", to: "channels/index.js"

# Pin specific channel files explicitly
pin "channels/consumer", to: "channels/consumer.js"
pin "channels/hub/notification_channel", to: "channels/hub/notification_channel.js"

# Ensure proper channel connections for namespaced channels
pin "consumer", to: "channels/consumer.js"

# Pin utility modules
pin_all_from "app/javascript/utilities", under: "utilities"
