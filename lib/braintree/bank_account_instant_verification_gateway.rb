module Braintree
  class BankAccountInstantVerificationGateway

    CREATE_TOKEN_MUTATION =
      "mutation CreateBankAccountInstantVerificationToken($input: CreateBankAccountInstantVerificationTokenInput!) { " +
      "createBankAccountInstantVerificationToken(input: $input) {" +
      "    clientMutationId" +
      "    token" +
      "  }" +
      "}"

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create_token(request)
      variables = request.to_graphql_variables

      begin
        response = @gateway.graphql_client.query(CREATE_TOKEN_MUTATION, variables)
        errors = GraphQLClient.get_validation_errors(response)

        if errors
          ErrorResult.new(@gateway, {errors: errors})
        else
          data = response[:data][:create_bank_account_instant_verification_token]

          token_attrs = {
            :token => data[:token],
            :client_mutation_id => data[:client_mutation_id]
          }

          SuccessfulResult.new(:bank_account_instant_verification_token => BankAccountInstantVerificationToken._new(token_attrs))
        end
      rescue StandardError => e
        raise UnexpectedException, "Couldn't parse response: #{e.message}"
      end
    end
  end
end