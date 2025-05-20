#Experimental
# This is a work in progress and may change in the future.
module Braintree
    class PayPalPurchaseUnitInput
        include BaseModule

        attr_reader :attrs
        attr_reader :amount
        attr_reader :payee

        def initialize(attributes)
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
            @payee = attributes[:payee] ? PayPalPayeeInput.new(attributes[:payee]) : nil
            @amount = attributes[:amount] ? MonetaryAmountInput.new(attributes[:amount]) : nil
        end
        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end
        def to_graphql_variables
            variables = {}
            variables["amount"] = amount.to_graphql_variables if amount
            variables["payee"] = payee.to_graphql_variables if payee
            variables
        end
    end
end