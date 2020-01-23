# frozen_string_literal: true

module Teckel
  # @abstract The interface an {Operation}s result object needs to adopt.
  #
  # @example
  #   class MyResult
  #     include Teckel::Result
  #
  #     def initialize(value, success)
  #       @value = value
  #       @success = (!!success).freeze
  #     end
  #
  #     def successful?; @success end
  #
  #     def value; @value end
  #   end
  module Result
    module ClassMethods
      def [](value, success)
        new(value, success)
      end
    end

    module InstanceMethods
      # Whether this is a success result
      # @return [Boolean]
      def successful?
        raise NotImplementedError, "Result object does not implement `successful?`"
      end

      # Whether this is a error/failure result
      # @return [Boolean]
      def failure?
        !successful?
      end

      # @!attribute [r] value
      # @return [Mixed] the value/payload
      def value
        raise NotImplementedError, "Result object does not implement `value`"
      end

      def deconstruct
        [successful?, value]
      end

      def deconstruct_keys(keys)
        {}.tap do |e|
          e[:success] = successful? if keys.include?(:success)
          e[:value] = value if keys.include?(:value)
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
