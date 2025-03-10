module CanonicalNaming
  extend ActiveSupport::Concern

  included do
    def canonical_name
      ancestors_chain = []
      current = self

      while current && current.respond_to?(:name)
        # Skip Location
        ancestors_chain.unshift(current.name) unless current.is_a?(Location)

        # Navigate up the chain using the appropriate association
        current = case current
                 when Row
                   current.parcel
                 when Parcel
                   current.orchard
                 when Orchard
                   current.farm
                 else
                   nil
                 end
      end

      ancestors_chain.join('-')
    end
  end
end
