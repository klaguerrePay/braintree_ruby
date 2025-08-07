require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::BankAccountInstantVerificationTokenRequest do
  describe "to_graphql_variables" do
    it "includes all fields when present" do
      request = Braintree::BankAccountInstantVerificationTokenRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
        :client_mutation_id => "test-client-id"
      )

      variables = request.to_graphql_variables

      expect(variables).not_to be_nil
      expect(variables).to have_key(:input)
      
      input = variables[:input]
      
      expect(input[:business_name]).to eq("Test Business")
      expect(input[:return_url]).to eq("https://example.com/success")
      expect(input[:cancel_url]).to eq("https://example.com/cancel")
      expect(input[:client_mutation_id]).to eq("test-client-id")
    end

    it "only includes non-null fields" do
      request = Braintree::BankAccountInstantVerificationTokenRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success"
      )

      variables = request.to_graphql_variables

      input = variables[:input]
      
      expect(input[:business_name]).to eq("Test Business")
      expect(input[:return_url]).to eq("https://example.com/success")
      expect(input).not_to have_key(:cancel_url)
      expect(input).not_to have_key(:client_mutation_id)
    end

    it "handles empty request" do
      request = Braintree::BankAccountInstantVerificationTokenRequest.new

      variables = request.to_graphql_variables

      expect(variables).to eq({ :input => {} })
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting all attributes" do
      request = Braintree::BankAccountInstantVerificationTokenRequest.new

      request.business_name = "Test Business"
      request.return_url = "https://example.com/success"
      request.cancel_url = "https://example.com/cancel"
      request.client_mutation_id = "test-client-id"

      expect(request.business_name).to eq("Test Business")
      expect(request.return_url).to eq("https://example.com/success")
      expect(request.cancel_url).to eq("https://example.com/cancel")
      expect(request.client_mutation_id).to eq("test-client-id")
    end

    it "initializes with hash of attributes" do
      request = Braintree::BankAccountInstantVerificationTokenRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
        :client_mutation_id => "test-client-id"
      )

      expect(request.business_name).to eq("Test Business")
      expect(request.return_url).to eq("https://example.com/success")
      expect(request.cancel_url).to eq("https://example.com/cancel")
      expect(request.client_mutation_id).to eq("test-client-id")
    end
  end
end