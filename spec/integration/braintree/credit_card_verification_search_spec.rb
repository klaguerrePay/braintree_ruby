require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CreditCardVerification, "search" do
  it "correctly returns a result with no matches" do
    collection = Braintree::CreditCardVerification.search do |search|
      search.credit_card_cardholder_name.is "thisnameisnotreal"
    end

    puts "\n=== DEBUG: Credit Card Verification Search Results ==="
    puts "Collection class: #{collection.class}"
    puts "Maximum size: #{collection.maximum_size}"

    # Try different ways to access the results
    results_array = collection.to_a
    puts "Results array length: #{results_array.length}"
    puts "Results array class: #{results_array.class}"

    # Check if collection responds to other methods
    puts "Collection responds to each?: #{collection.respond_to?(:each)}"
    puts "Collection responds to first?: #{collection.respond_to?(:first)}"
    puts "Collection responds to count?: #{collection.respond_to?(:count)}"

    # Try to get first result
    if collection.respond_to?(:first)
      begin
        first_result = collection.first
        puts "First result: #{first_result.inspect}"
        puts "First result class: #{first_result.class}" if first_result
      rescue => e
        puts "Error getting first result: #{e.message}"
      end
    end

    # Try to iterate and see if we get any items
    puts "\nAttempting to iterate through collection:"
    count = 0
    begin
      collection.each do |verification|
        count += 1
        puts "  Found verification #{count}: #{verification.id}"
        puts "    Cardholder Name: #{verification.credit_card[:cardholder_name]}"
        puts "    Status: #{verification.status}"
        puts "    Created At: #{verification.created_at}"
        break if count >= 5 # Limit output
      end
    rescue => e
      puts "Error during iteration: #{e.message}"
    end
    puts "Total items found during iteration: #{count}"

    # Check instance variables
    puts "\nCollection instance variables:"
    collection.instance_variables.each do |var|
      begin
        value = collection.instance_variable_get(var)
        puts "  #{var}: #{value.inspect}"
      rescue => e
        puts "  #{var}: Error reading - #{e.message}"
      end
    end

    puts "=== END DEBUG ==="

    expect(collection.maximum_size).to eq(0)
  end

  it "can search on text fields" do
    unsuccessful_result = Braintree::Customer.create(
      :credit_card => {
      :cardholder_name => "Tom Smith",
      :expiration_date => "05/2012",
      :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
      :options => {
      :verify_card => true
    }
    })

    verification = unsuccessful_result.credit_card_verification

    search_criteria = {
      :credit_card_cardholder_name => "Tom Smith",
      :credit_card_expiration_date => "05/2012",
      :credit_card_number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa
    }

    search_criteria.each do |criterion, value|
      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.send(criterion).is value
      end
      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(verification.id)

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.send(criterion).is("invalid_attribute")
      end
      expect(collection).to be_empty
    end

    collection = Braintree::CreditCardVerification.search do |search|
      search.id.is verification.id
      search_criteria.each do |criterion, value|
        search.send(criterion).is value
      end
    end

    expect(collection.maximum_size).to eq(1)
    expect(collection.first.id).to eq(verification.id)
  end

  describe "multiple value fields" do
    it "searches on ids" do
      unsuccessful_result1 = Braintree::Customer.create(
        :credit_card => {
        :cardholder_name => "Tom Smith",
        :expiration_date => "05/2012",
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :options => {
        :verify_card => true
      }
      })

      verification_id1 = unsuccessful_result1.credit_card_verification.id

      unsuccessful_result2 = Braintree::Customer.create(
        :credit_card => {
        :cardholder_name => "Tom Smith",
        :expiration_date => "05/2012",
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :options => {
        :verify_card => true
      }
      })

      verification_id2 = unsuccessful_result2.credit_card_verification.id

      collection = Braintree::CreditCardVerification.search do |search|
        search.ids.in verification_id1, verification_id2
      end

      expect(collection.maximum_size).to eq(2)
    end
  end

  context "range fields" do
    it "searches on created_at" do
      unsuccessful_result = Braintree::Customer.create(
        :credit_card => {
        :cardholder_name => "Tom Smith",
        :expiration_date => "05/2012",
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :options => {
        :verify_card => true
      }
      })

      verification = unsuccessful_result.credit_card_verification

      created_at = verification.created_at

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.created_at.between(
          created_at - 60,
          created_at + 60,
        )
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(verification.id)

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.created_at >= created_at - 1
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(verification.id)

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.created_at <= created_at + 1
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(verification.id)

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.created_at.between(
          created_at - 300,
          created_at - 100,
        )
      end

      expect(collection.maximum_size).to eq(0)

      collection = Braintree::CreditCardVerification.search do |search|
        search.id.is verification.id
        search.created_at.is created_at
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(verification.id)
    end
  end

  context "pagination" do
    it "is not affected by new results on the server" do
      cardholder_name = "Tom Smith #{rand(1_000_000)}"
      5.times do |index|
        Braintree::Customer.create(
          :credit_card => {
            :cardholder_name => "#{cardholder_name} #{index}",
            :expiration_date => "05/2012",
            :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
            :options => {
              :verify_card => true
            }
          })
      end

      collection = Braintree::CreditCardVerification.search do |search|
        search.credit_card_cardholder_name.starts_with cardholder_name
      end

      count_before_new_data = collection.instance_variable_get(:@ids).count

      new_cardholder_name = "#{cardholder_name} shouldn't be included"
      Braintree::Customer.create(
        :credit_card => {
          :cardholder_name => new_cardholder_name,
          :expiration_date => "05/2012",
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
          :options => {
            :verify_card => true
          }
        })

      verifications = collection.to_a
      expect(verifications.count).to eq(count_before_new_data)

      cardholder_names = verifications.map { |verification| verification.credit_card[:cardholder_name] }
      expect(cardholder_names).to_not include(new_cardholder_name)
    end
  end
end
