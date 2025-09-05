require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::BankAccountInstantVerificationGateway do
  before do
    @gateway = Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "integration2_merchant_id",
      :public_key => "integration2_public_key",
      :private_key => "integration2_private_key",
    )
  end

  describe "create_jwt" do
    it "creates a jwt with valid request" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "PP",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
        :client_mutation_id => "test-mutation-#{Time.now.to_i}",
      )

      result = @gateway.bank_account_instant_verification.create_jwt(request)

      unless result.success?
        puts "DEBUG: Result failed!"
        puts "DEBUG: Errors: #{result.errors.inspect}" if result.respond_to?(:errors)
      end

      expect(result.success?).to eq(true)
      expect(result.bank_account_instant_verification_jwt).not_to be_nil
      expect(result.bank_account_instant_verification_jwt.jwt).not_to be_nil
      expect(result.bank_account_instant_verification_jwt.jwt).not_to be_empty

      # JWT tokens should start with "eyJ" when base64 encoded
      expect(result.bank_account_instant_verification_jwt.jwt).to start_with("eyJ")

      if request.client_mutation_id
        expect(result.bank_account_instant_verification_jwt.client_mutation_id).to eq(request.client_mutation_id)
      end
    end

    it "fails with invalid business name" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "", # Empty business name should cause validation error
        :return_url => "https://example.com/return",
        :cancel_url => "https://example.com/cancel",
      )

      result = @gateway.bank_account_instant_verification.create_jwt(request)

      # Skip test if Bank Account Instant Verification is not enabled for this merchant
      if !result.success? && result.errors.to_s.include?("Bank Account Instant Verification not enabled")
        pending "Bank Account Instant Verification not enabled for test merchant"
      end

      expect(result.success?).to eq(false)
      expect(result.errors).not_to be_nil
    end

    it "fails with invalid URLs" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "PP",
        :return_url => "not-a-valid-url",
        :cancel_url => "also-not-valid",
      )

      result = @gateway.bank_account_instant_verification.create_jwt(request)

      # Skip test if Bank Account Instant Verification is not enabled for this merchant
      if !result.success? && result.errors.to_s.include?("Bank Account Instant Verification not enabled")
        pending "Bank Account Instant Verification not enabled for test merchant"
      end

      expect(result.success?).to eq(false)
      expect(result.errors).not_to be_nil
    end
  end

  describe "transaction with ACH mandate" do
    it "creates transaction with ACH mandate" do
      customer_result = @gateway.customer.create({})
      expect(customer_result.success?).to eq(true)
      customer = customer_result.customer

      nonce = generate_valid_us_bank_account_nonce(@gateway)
      payment_method_request = {
        :customer_id => customer.id,
        :payment_method_nonce => nonce,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId
        }
      }

      payment_method_result = @gateway.payment_method.create(payment_method_request)
      expect(payment_method_result.success?).to eq(true)

      us_bank_account = payment_method_result.payment_method

      mandate_accepted_at = Time.now - 600 # 10 minutes ago

      transaction_request = {
        :amount => "100.00",
        :payment_method_token => us_bank_account.token,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        :us_bank_account => {
          :ach_mandate_text => "I authorize this ACH debit transaction for the amount shown above",
          :ach_mandate_accepted_at => mandate_accepted_at
        },
        :options => {
          :submit_for_settlement => true
        }
      }

      result = @gateway.transaction.sale(transaction_request)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.id).not_to be_nil
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.us_bank_account_details).not_to be_nil
      expect(transaction.us_bank_account_details.token).to eq(us_bank_account.token)
    end

    it "creates transaction with only ACH mandate text" do
      customer_result = @gateway.customer.create({})
      expect(customer_result.success?).to eq(true)
      customer = customer_result.customer

      nonce = generate_valid_us_bank_account_nonce(@gateway)
      payment_method_request = {
        :customer_id => customer.id,
        :payment_method_nonce => nonce,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId
        }
      }

      payment_method_result = @gateway.payment_method.create(payment_method_request)
      expect(payment_method_result.success?).to eq(true)

      us_bank_account = payment_method_result.payment_method

      transaction_request = {
        :amount => "50.00",
        :payment_method_token => us_bank_account.token,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        :us_bank_account => {
          :ach_mandate_text => "I authorize this ACH debit transaction",
          :ach_mandate_accepted_at => Time.now
        },
        :options => {
          :submit_for_settlement => true
        }
      }

      result = @gateway.transaction.sale(transaction_request)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.id).not_to be_nil
      expect(transaction.amount).to eq(BigDecimal("50.00"))
    end
  end

  describe "us bank account verification with instant verification method" do
    it "verifies bank account with instant verification method" do
      customer_result = @gateway.customer.create({})
      expect(customer_result.success?).to eq(true)
      customer = customer_result.customer

      nonce = generate_valid_us_bank_account_nonce(@gateway)
      request = {
        :customer_id => customer.id,
        :payment_method_nonce => nonce,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId
        }
      }

      result = @gateway.payment_method.create(request)
      expect(result.success?).to eq(true)

      us_bank_account = result.payment_method
      expect(us_bank_account.verifications).not_to be_nil

      unless us_bank_account.verifications.empty?
        verification = us_bank_account.verifications.first
        expect(verification.verification_method).not_to be_nil

        expect([
          Braintree::UsBankAccountVerification::VerificationMethod::InstantVerification,
          Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck,
          Braintree::UsBankAccountVerification::VerificationMethod::MicroTransfers,
          Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
          Braintree::UsBankAccountVerification::VerificationMethod::TokenizedCheck
        ]).to include(verification.verification_method)
      end
    end
  end

  describe "vault US bank with ACH mandate" do
    it "vaults payment method and provides ACH mandate information at vault time (instant verification)" do
      customer_result = @gateway.customer.create({})
      expect(customer_result.success?).to eq(true)
      customer = customer_result.customer

      nonce = generate_bank_account_instant_verification_nonce(@gateway)

      mandate_accepted_at = Time.now - 300 # 5 minutes ago

      # Vault payment method and provide ACH mandate information at vault time (instant verification)
      payment_method_request = {
        :customer_id => customer.id,
        :payment_method_nonce => nonce,
        :us_bank_account => {
          :ach_mandate_text => "I authorize this transaction and future debits",
          :ach_mandate_accepted_at => mandate_accepted_at
        },
        :options => {
          :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId
        }
      }

      payment_method_result = @gateway.payment_method.create(payment_method_request)

      expect(payment_method_result.success?).to eq(true), "Expected payment method creation success but got failure with validation errors (see console output)"

      us_bank_account = payment_method_result.payment_method

      expect(us_bank_account.ach_mandate).not_to be_nil
      expect(us_bank_account.ach_mandate.text).not_to be_nil
      expect(us_bank_account.ach_mandate.accepted_at).not_to be_nil

      expect(us_bank_account.last_4).to eq("1234")
      expect(us_bank_account.routing_number).to eq("021000021")
      expect(us_bank_account.account_type).to eq("checking")
    end
  end

  describe "charge US bank with ACH mandate" do
    it "creates transaction directly with nonce and provides ACH mandate at transaction time (instant verification)" do
      nonce = generate_bank_account_instant_verification_nonce(@gateway)

      mandate_accepted_at = Time.now - 300 # 5 minutes ago

      # Create transaction directly with nonce and provide ACH mandate at transaction time (instant verification)
      transaction_request = {
        :amount => "12.34",
        :payment_method_nonce => nonce,
        :merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
        :us_bank_account => {
          :ach_mandate_text => "I authorize this transaction and future debits",
          :ach_mandate_accepted_at => mandate_accepted_at
        },
        :options => {
          :submit_for_settlement => true
        }
      }

      transaction_result = @gateway.transaction.sale(transaction_request)

      expect(transaction_result.success?).to eq(true), "Expected transaction success but got failure with validation errors (see console output)"
      transaction = transaction_result.transaction

      expect(transaction.id).not_to be_nil
      expect(transaction.amount).to eq(BigDecimal("12.34"))
      expect(transaction.us_bank_account_details).not_to be_nil

      expect(transaction.us_bank_account_details.ach_mandate).not_to be_nil
      expect(transaction.us_bank_account_details.ach_mandate.text).not_to be_nil
      expect(transaction.us_bank_account_details.ach_mandate.accepted_at).not_to be_nil

      expect(transaction.us_bank_account_details.account_holder_name).to eq("Dan Schulman")
      expect(transaction.us_bank_account_details.last_4).to eq("1234")
      expect(transaction.us_bank_account_details.routing_number).to eq("021000021")
      expect(transaction.us_bank_account_details.account_type).to eq("checking")
    end
  end

  private

  def generate_valid_us_bank_account_nonce(gateway)
    generate_non_plaid_us_bank_account_nonce
  end

  def generate_bank_account_instant_verification_nonce(gateway)
    # This method should generate a nonce specifically for instant verification testing
    # Similar to Java's TestHelper.generatesBankAccountInstantVerificationNonce(gateway)
    generate_non_plaid_us_bank_account_nonce
  end
end