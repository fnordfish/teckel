# frozen_string_literal: true

require 'forwardable'

module Teckel
  module Chain
    class Result < Teckel::Operation::Result
      extend Forwardable

      # @param value [Object] The result value
      # @param success [Boolean] whether this is a successful result
      # @param step [Teckel::Chain::Step]
      def initialize(value, success, step)
        super(value, success)
        @step = step
      end

      class << self
        alias :[] :new
      end

      # @!method step
      #   Delegates to +step.name+
      #   @return [String,Symbol] The step name of the failed operation.
      def_delegator :@step, :name, :step

      def deconstruct
        [successful?, @step.name, value]
      end

      def deconstruct_keys(keys)
        super.tap { |e|
          e[:step] = @step.name if keys.include?(:step)
        }
      end
    end
  end
end
