module Braintree
  class MerchantAccount
    include BaseModule

    module Status
      Pending = "pending"
      Active = "active"
      Suspended = "suspended"
    end

    attr_reader :business_details
    attr_reader :currency_iso_code
    attr_reader :default
    attr_reader :funding_details
    attr_reader :id
    attr_reader :individual_details
    attr_reader :master_merchant_account
    attr_reader :status

    alias_method :default?, :default

    def self.find(*args)
      Configuration.gateway.merchant_account.find(*args)
    end

    def initialize(gateway, attributes)
      @gateway = gateway
      @individual_details = IndividualDetails.new(@individual)
      @business_details = BusinessDetails.new(@business)
      @funding_details = FundingDetails.new(@funding)
      @master_merchant_account = MerchantAccount._new(@gateway, attributes.delete(:master_merchant_account)) if attributes[:master_merchant_account]
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
