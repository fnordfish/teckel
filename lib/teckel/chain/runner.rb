# frozen_string_literal: true

module Teckel
  module Chain
    # The default implementation for executing a {Chain}
    #
    # @!visibility protected
    class Runner
      # @!visibility private
      # @return [Object]
      UNDEFINED = Object.new

      # @!visibility private
      # @attr [Object] value the return value / result of the step execution
      # @attr [Boolean] success whether the step has been executed successfully
      # @attr [Teckel::Chain::Step] the step instance
      StepResult = Struct.new(:value, :success, :step)

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
      def call(input = nil)
        step_result = run(input)
        chain.result_constructor.call(*step_result)
      end

      def steps
        settings.eql?(UNDEFINED) ? chain.steps : steps_with_settings
      end

      private

      def run(input)
        steps.each_with_object(StepResult.new(input)) do |step, step_result|
          result = step.operation.call(step_result.value)

          step_result.step = step
          step_result.value = result.value
          step_result.success = result.successful?

          break step_result if result.failure?
        end
      end

      def step_with_settings(step)
        settings.key?(step.name) ? step.with(settings[step.name]) : step
      end

      def steps_with_settings
        Enumerator.new do |yielder|
          chain.steps.each do |step|
            yielder << step_with_settings(step)
          end
        end
      end
    end
  end
end
