require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::TestSubscription do
  context "self.recurring" do
    before(:each) do
      @credit_card = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "10/2021"
        },
      ).credit_cards[0]

      @subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
    end

    it "should success for todays date" do
      result = Braintree::TestSubscription.recurring(@subscription.id, Date.today)
      expect(result.success?).to be_truthy
      expect(result.success).to eq true
    end

    it "should return false for past date" do
      result = Braintree::TestSubscription.recurring(@subscription.id, Date.today - 2)
      expect(result.success?).to be_falsey
    end

    it "raises NotFoundError if it cannot find subscription" do
      expect {
        Braintree::TestSubscription.recurring("duplicateId", Date.today)
      }.to raise_error(Braintree::NotFoundError, 'subscription with id "duplicateId" not found')
    end
  end
end
