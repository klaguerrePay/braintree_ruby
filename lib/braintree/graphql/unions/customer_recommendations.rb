# A union of all possible customer recommendations associated with a PayPal customer session.

#Experimental
# This is a work in progress and may change in the future.
module Braintree
  class CustomerRecommendations
    include BaseModule

    attr_reader :payment_options, :payment_recommendations

    def initialize(attributes = {})
      @payment_options = initialize_payment_options(attributes[:payment_options])
      @payment_recommendations = initialize_payment_recommendations(attributes[:payment_recommendations])

      # If payment_options wasn't explicitly provided but payment_recommendations was,
      # create payment_options from payment_recommendations
      if attributes[:payment_options].nil? && !@payment_recommendations.empty?
        @payment_options = @payment_recommendations.map do |recommendation|
          PaymentOptions._new(
            payment_option: recommendation.payment_option,
            recommended_priority: recommendation.recommended_priority,
          )
        end
      end
    end

    def inspect
      "#<#{self.class} payment_options: #{payment_options.inspect}, payment_recommendations: #{payment_recommendations.inspect}>"
    end

    private

    def initialize_payment_options(payment_options)
      return [] if payment_options.nil?

      payment_options.map do |payment_options_hash|
        PaymentOptions._new(payment_options_hash)
      end
    end

    def initialize_payment_recommendations(payment_recommendations)
      return [] if payment_recommendations.nil?

      payment_recommendations.map do |recommendation_hash|
        if recommendation_hash.is_a?(PaymentRecommendations)
          recommendation_hash
        else
          PaymentRecommendations._new(recommendation_hash)
        end
      end
    end

    class << self
      def _new(attributes = {})
        new(attributes)
      end
    end
  end
end