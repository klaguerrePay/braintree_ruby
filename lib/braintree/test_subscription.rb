module Braintree
  class TestSubscription < Subscription
    def self.recurring(subscription_id, date)
      Configuration.gateway.testing.recurring(subscription_id, date)
    end
  end
end
