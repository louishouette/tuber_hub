- separate logic with namespaces
module ERP
  module Commerce
    module Clients
      # Code for customers
    end
    module Sales
      # Code for sales and related processes
    end
    module Billing
      # Code for invoices and payment processing
    end
    module Delivery
      # Code for delivery notes and scheduling
    end
  end

  module Operations
    module Production
      # Code for managing production workflows and outputs
    end
    module Stock
      # Code for inventory, categorization, and sorting
    end
    module Logistics
      module Shipments
        # Code for shipment management
      end
      module Returns
        # Code for handling returns and exchanges
      end
    end
  end
end
