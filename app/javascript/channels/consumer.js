// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

let consumerInstance = null;

try {
  // Create a consumer and connect to /cable endpoint
  console.log('Creating Action Cable consumer...');
  consumerInstance = createConsumer('/cable');
  console.log('Action Cable consumer created successfully:', consumerInstance);
} catch (error) {
  console.error('Failed to create Action Cable consumer:', error);
}

export default consumerInstance;
