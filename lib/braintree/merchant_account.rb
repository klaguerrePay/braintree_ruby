module Braintree
  class MerchantAccount
    include BaseModule

    module Status
      Pending = "pending"
      Active = "active"
      Suspended = "suspended"
    end

    attr_reader :currency_iso_code
    attr_reader :default
    attr_reader :id
    attr_reader :status

    alias_method :default?, :default

    def self.find(*args)
      Configuration.gateway.merchant_account.find(*args)
    end

    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
        end

    class << self
      protected :new
      def _new(*args)
        self.new(*args)
      end
    end

    def inspect
      order = [:id, :status, :master_merchant_account]
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class}: #{nice_attributes.join(', ')}>"
    end
  end
end
