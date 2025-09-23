require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::UsBankAccountVerification do
  it "verifies VerificationMethod constants, All array, and parses instant_verification method" do
    expect(Braintree::UsBankAccountVerification::VerificationMethod::InstantVerification).to eq("instant_verification")

    expect(Braintree::UsBankAccountVerification::VerificationMethod::All).to include(
      Braintree::UsBankAccountVerification::VerificationMethod::InstantVerification,
    )

    all_methods = Braintree::UsBankAccountVerification::VerificationMethod::All
    expect(all_methods).to include(Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck)
    expect(all_methods).to include(Braintree::UsBankAccountVerification::VerificationMethod::InstantVerification)
    expect(all_methods).to include(Braintree::UsBankAccountVerification::VerificationMethod::MicroTransfers)
    expect(all_methods).to include(Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck)
    expect(all_methods).to include(Braintree::UsBankAccountVerification::VerificationMethod::TokenizedCheck)

    xml = <<-XML
      <us-bank-account-verification>
        <status>verified</status>
        <gateway-rejection-reason nil="true"/>
        <merchant-account-id>ygmxmpdxthqrrtfyisqahvclo</merchant-account-id>
        <processor-response-code>1000</processor-response-code>
        <processor-response-text>Approved</processor-response-text>
        <id>inst_verification_id</id>
        <verification-method>instant_verification</verification-method>
        <us-bank-account>
          <token>instant_token</token>
          <last-4>5678</last-4>
          <account-type>savings</account-type>
          <account-holder-name>John Doe</account-holder-name>
          <bank-name>Chase Bank</bank-name>
          <routing-number>987654321</routing-number>
        </us-bank-account>
        <created-at type="datetime">2024-01-15T10:30:00Z</created-at>
      </us-bank-account-verification>
    XML

    node = Braintree::Xml::Parser.hash_from_xml(xml)[:us_bank_account_verification]
    verification = Braintree::UsBankAccountVerification._new(node)

    expect(verification.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
    expect(verification.verification_method).to eq(Braintree::UsBankAccountVerification::VerificationMethod::InstantVerification)
    expect(verification.id).to eq("inst_verification_id")
    expect(verification.us_bank_account.token).to eq("instant_token")
  end
end