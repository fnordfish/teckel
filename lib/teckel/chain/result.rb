# frozen_string_literal: true

module Teckel
  module Chain
    class Result < Teckel::Operation::Result
      # @param value [Object] The result value
      # @param success [Boolean] whether this is a successful result
      # @param step [Teckel::Chain::Step]
      def initialize(value, success, step)
        super(value, success)
        @step = step
      end

      class << self
        alias_method :[], :new
      end

      # @return [String,Symbol] The step name of the failed operation.
      def step
        @step.name
      end

      def deconstruct
        [successful?, @step.name, value]
      end

      def deconstruct_keys(keys)
        e = super
        e[:step] = @step.name if keys.include?(:step)
        e
      end
    end
  end
end
