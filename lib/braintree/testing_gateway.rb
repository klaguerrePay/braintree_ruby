module Braintree
  class TestingGateway # :nodoc:

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
      @transaction_gateway = TransactionGateway.new(gateway)
    end

    def settle(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settle")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_confirm(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_confirm")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_decline(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_decline")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_pending(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_pending")
      @transaction_gateway._handle_transaction_response(response)
    end

    def recurring(subscription_id, date)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/subscriptions/#{subscription_id}/recurring?date=#{date}")
      result = response[:response]
      if result[:success]
        SuccessfulResult.new(:success => result[:success])
      elsif result[:error]
        ErrorResult.new(@gateway, {errors: {error: result[:error]}})
      end
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{subscription_id.inspect} not found"
    end

    def check_environment
      raise TestOperationPerformedInProduction if @config.environment == :production
    end
  end
end
