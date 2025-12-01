module Braintree
  class CreditCardVerificationGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def find(id)
      raise ArgumentError if id.nil? || id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/verifications/#{id}")
      CreditCardVerification._new(response[:verification])
    rescue NotFoundError
      raise NotFoundError, "verification with id #{id.inspect} not found"
    end

    def search(&block)
      search = CreditCardVerificationSearch.new
      block.call(search) if block

      puts "\n=== DEBUG search ==="
      puts "Search criteria: #{search.to_hash.inspect}"
      # Add verification_type to filter to only credit card verifications
      # Gateway defaults to returning both CC and US bank account verifications if merchant accepts US bank accounts
      search_params = search.to_hash.merge({:verification_type => ["credit_card"]})
      puts "Search criteria with type filter: #{search_params.inspect}"
      response = @config.http.post("#{@config.base_merchant_path}/verifications/advanced_search_ids", {:search => search_params})
      puts "Search IDs response: #{response.inspect}"
      puts "=== END DEBUG search ===\n"
      ResourceCollection.new(response) { |ids| _fetch_verifications(search, ids) }
    end

    def create(params)
      response = @config.http.post("#{@config.base_merchant_path}/verifications", :verification => params)
      _handle_verification_create_response(response)
    end

    def _handle_verification_create_response(response)
      if response[:verification]
        SuccessfulResult.new(:verification => CreditCardVerification._new(response[:verification]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :verification or :api_error_response"
      end
    end

    def _fetch_verifications(search, ids)
      search.ids.in ids
      puts "\n=== DEBUG _fetch_verifications ==="
      puts "Fetching verifications for IDs: #{ids.inspect}"
      # Add verification_type to filter to only credit card verifications
      search_params = search.to_hash.merge({:verification_type => ["credit_card"]})
      puts "Search params with type filter: #{search_params.inspect}"
      response = @config.http.post("#{@config.base_merchant_path}/verifications/advanced_search", {:search => search_params})
      puts "Response keys: #{response.keys.inspect}"
      attributes = response[:credit_card_verifications]
      puts "Attributes: #{attributes.inspect}"

      # Extract credit card verifications only
      verifications = Util.extract_attribute_as_array(attributes, :verification).map { |attrs| CreditCardVerification._new(attrs) }

      # Log if we received US bank account verifications (which shouldn't happen with the type filter)
      us_bank_verifications = Util.extract_attribute_as_array(attributes.dup, :us_bank_account_verification)
      if us_bank_verifications.any?
        puts "WARNING: Gateway returned #{us_bank_verifications.length} US bank account verifications despite type filter - this is a gateway bug"
      end

      puts "Extracted #{verifications.length} credit card verifications"
      puts "=== END DEBUG _fetch_verifications ===\n"
      verifications
    end

    def self._create_signature
      [
        {:credit_card => [
          {:billing_address => AddressGateway._shared_signature},
          :cardholder_name,
          :cvv,
          :expiration_date,
          :expiration_month,
          :expiration_year,
          :number,
        ]},
        {:external_vault => [
          :previous_network_transaction_id,
          :status,
        ]},
        :intended_transaction_source,
        {:options => [
          :account_information_inquiry,
          :account_type,
          :amount,
          :merchant_account_id,
        ]},
        :payment_method_nonce,
        {:risk_data => [
          :customer_browser,
          :customer_ip,
        ]},
        :three_d_secure_authentication_id,
        {:three_d_secure_pass_thru => [
          :authentication_response,
          :cavv,
          :cavv_algorithm,
          :directory_response,
          :ds_transaction_id,
          :eci_flag,
          :three_d_secure_version,
          :xid,
        ]},
      ]
    end
  end
end
