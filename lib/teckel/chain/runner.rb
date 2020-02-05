# frozen_string_literal: true

module Teckel
  module Chain
    # The default implementation for executing a {Chain}
    #
    # @!visibility protected
    class Runner
      # @!visibility private
      UNDEFINED = Object.new

      def initialize(chain, settings = UNDEFINED)
        @chain, @settings = chain, settings
      end
      attr_reader :chain, :settings

      # Run steps
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Chain::Result] The result object wrapping
      #   either the success or failure value.
      def call(input)
        last_result = nil
        last_step = nil
        steps.each do |step|
          last_step = step
          value     = last_result ? last_result.value : input

          last_result = step.operation.call(value)

          break if last_result.failure?
        end

        chain.result_constructor.call(last_result.value, last_result.successful?, last_step)
      end

      def steps
        if settings == UNDEFINED
          chain.steps
        else
          Enumerator.new do |yielder|
            chain.steps.each do |step|
              yielder << (settings.key?(step.name) ? step.with(settings[step.name]) : step)
            end
          end
        end
      end
    end
  end
end
