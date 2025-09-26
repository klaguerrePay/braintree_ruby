module Braintree
  class BankAccountInstantVerificationJwtRequest
    attr_accessor :business_name, :return_url, :cancel_url

    def initialize(attributes = {})
      set_instance_variables_from_hash(attributes) if respond_to?(:set_instance_variables_from_hash)
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def to_graphql_variables
      variables = {:input => {}}

      variables[:input][:businessName] = business_name if business_name
      variables[:input][:returnUrl] = return_url if return_url
      variables[:input][:cancelUrl] = cancel_url if cancel_url

      variables
    end
  end
end