# frozen_string_literal: true

module Teckel
  module Operation
    # The default implementation for executing a single {Operation}
    # @note You shouldn't need to call this explicitly.
    #   Use {ClassMethods#with MyOperation.with()} or {ClassMethods#with MyOperation.call()} instead.
    # @!visibility protected
    class Runner
      # @!visibility private
      UNDEFINED = Object.new.freeze

      def initialize(operation, settings = UNDEFINED)
        @operation, @settings = operation, settings
      end
      attr_reader :operation, :settings

      def call(input = nil)
        err = catch(:failure) do
          simple_return = UNDEFINED
          out = catch(:success) do
            simple_return = run(build_input(input))
          end

          if simple_return != UNDEFINED
            Kernel.warn "[Deprecated] #{operation}#call Simple return values for Teckel Operations are deprecated. Use `success!` instead."
            return build_output(simple_return)
          end

          return out
        end

        err
      end

      # This is just here to raise a meaningful error.
      # @!visibility private
      def with(*)
        raise Teckel::Error, "Operation already has settings assigned."
      end

      def success!(*args)
        output = build_output(*args)
        throw :success, output
      end

      def fail!(*args)
        output = build_error(*args)
        throw :failure, output
      end

      private

      def run(input)
        op = @operation.new
        op.runner = self
        op.settings = settings if settings != UNDEFINED
        op.call(input)
      end

      def build_input(input)
        operation.input_constructor.call(input)
      end

      def build_output(*args)
        value =
          if args.size == 1 && operation.output === args.first # rubocop:disable Style/CaseEquality
            args.first
          else
            operation.output_constructor.call(*args)
          end

        operation.result_constructor.call(value, true)
      end

      def build_error(*args)
        value =
          if args.size == 1 && operation.error === args.first # rubocop:disable Style/CaseEquality
            args.first
          else
            operation.error_constructor.call(*args)
          end

        operation.result_constructor.call(value, false)
      end
    end
  end
end
