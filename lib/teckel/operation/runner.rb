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
            simple_return = call!(build_input(input))
          end
          return simple_return == UNDEFINED ? build_output(*out) : build_output(simple_return)
        end
        build_error(*err)
      end

      # This is just here to raise a meaningful error.
      # @!visibility private
      def with(*)
        raise Teckel::Error, "Operation already has settings assigned."
      end

      private

      def call!(input)
        op = @operation.new
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
