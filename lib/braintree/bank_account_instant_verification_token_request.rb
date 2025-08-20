module Braintree
  class BankAccountInstantVerificationTokenRequest
    attr_accessor :business_name, :return_url, :cancel_url, :client_mutation_id

    def initialize(attributes = {})
      set_instance_variables_from_hash(attributes) if respond_to?(:set_instance_variables_from_hash)
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def to_graphql_variables
      variables = {:input => {}}

      variables[:input][:business_name] = business_name if business_name
      variables[:input][:return_url] = return_url if return_url
      variables[:input][:cancel_url] = cancel_url if cancel_url
      variables[:input][:client_mutation_id] = client_mutation_id if client_mutation_id

      variables
    end
  end
end