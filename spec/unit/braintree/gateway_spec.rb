require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Gateway do
  let(:gateway) { Braintree::Gateway.new(:environment => :sandbox, :merchant_id => "test", :public_key => "test", :private_key => "test") }

  describe "bank_account_instant_verification" do
    it "returns a BankAccountInstantVerificationGateway instance" do
      bank_account_instant_verification_gateway = gateway.bank_account_instant_verification
      
      expect(bank_account_instant_verification_gateway).not_to be_nil
      expect(bank_account_instant_verification_gateway).to be_a(Braintree::BankAccountInstantVerificationGateway)
    end
  end
end