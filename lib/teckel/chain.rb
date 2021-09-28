# frozen_string_literal: true

require_relative 'chain/config'
require_relative 'chain/step'
require_relative 'chain/result'
require_relative 'chain/runner'

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
        steps.each_with_object([]) do |step, m|
          err = step.operation.error
          m << err if err
        end
      end

      # The primary interface to call the chain with the given input.
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Chain::Result] The result object wrapping
      #   the result value, the success state and last executed step.
      def call(input = nil)
        default_settings = self.default_settings

        runner =
          if default_settings
            self.runner.new(self, default_settings)
          else
            self.runner.new(self)
          end

        if around
          around.call(runner, input)
        else
          runner.call(input)
        end
      end

      # @param settings [Hash{String,Symbol => Object}] Set settings for a step by it's name
      def with(settings)
        runner = self.runner.new(self, settings)
        if around
          ->(input) { around.call(runner, input) }
        else
          runner
        end
      end
      alias :set :with
    end

    def self.included(receiver)
      receiver.class_eval do
        extend Config
        extend ClassMethods
      end
    end
  end
end
