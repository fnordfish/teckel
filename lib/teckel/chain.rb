# frozen_string_literal: true

require_relative "chain/config"
require_relative "chain/step"
require_relative "chain/result"
require_relative "chain/runner"

module Teckel
  # Railway style execution of multiple Operations.
  #
  # - Runs multiple Operations (steps) in order.
  # - The output of an earlier step is passed as input to the next step.
  # - Any failure will stop the execution chain (none of the later steps is called).
  # - All Operations (steps) must return a {Teckel::Result}
  # - The result is wrapped into a {Teckel::Chain::Result}
  #
  # @see Teckel::Operation#result!
  module Chain
    module ClassMethods
      # The expected input for this chain
      # @return [Class] The {Teckel::Operation.input} of the first step
      def input
        steps.first&.operation&.input
      end

      # The expected output for this chain
      # @return [Class] The {Teckel::Operation.output} of the last step
      def output
        steps.last&.operation&.output
      end

      # List of all possible errors
      # @return [<Class>] List of all steps {Teckel::Operation.error}s
      def errors
        steps.map { |step| step.operation.error }
      end

      # The primary interface to call the chain with the given input.
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Chain::Result] The result object wrapping
      #   the result value, the success state and last executed step.
      def call(input = nil)
        default_settings = default_settings()

        runner =
          if default_settings
            runner().new(self, default_settings)
          else
            runner().new(self)
          end

        if around
          around.call(runner, input)
        else
          runner.call(input)
        end
      end

      # Provide settings to the configured steps.
      #
      # @param settings [Hash{(String,Symbol) => Object}] Set settings for a step by it's name
      # @return [#call] A callable, either a {Teckel::Chain::Runner} or,
      #   when configured with an around hook, a +Proc+
      def with(settings)
        runner = runner().new(self, settings)
        if around
          around.curry[runner]
        else
          runner
        end
      end
      alias_method :set, :with
    end

    def self.included(receiver)
      receiver.class_eval do
        extend Config
        extend ClassMethods
      end
    end
  end
end
