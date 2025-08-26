module Braintree
  class BankAccountInstantVerificationJwt
    include BaseModule

    attr_reader :jwt, :client_mutation_id

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    def self._new(*args)
      self.new(*args)
    end

    def inspect
      attr_order = [:jwt, :client_mutation_id]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{formatted_attrs.join(', ')}>"
    end
  end
end