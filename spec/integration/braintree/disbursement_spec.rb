require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Disbursement do
  describe "transactions" do
    it "finds the transactions associated with the disbursement" do
      attributes = {
        :id => "123456",
        :merchant_account => {
          :id => "ma_card_processor_brazil",
          :status => "active"
        },
        transactionIds: ["transaction_with_installments_and_adjustments"],
        :amount => "100.00",
        :disbursement_date => "2013-04-10",
        :exception_message => "invalid_account_number",
        :follow_up_action => "update",
        :retry => false,
        :success => false
      }

      disbursement = Braintree::Disbursement._new(Braintree::Configuration.gateway, attributes)
      # expect(disbursement.transactions.maximum_size).to eq(1)
      transaction = disbursement.transactions.first
      expect(transaction.id).to eq("transaction_with_installments_and_adjustments")
    end
  end
end
