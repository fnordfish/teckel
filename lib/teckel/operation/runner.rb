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
        catch(:halt) do
          op = instance
          op_input = op.instance_exec(input, &operation.input_constructor)
          op.call(op_input)
          nil # return values need to go through +success!+ or +fail!+
        end
      end

      def instance
        return @instance if instance_variable_defined?(:@instance)

        op = operation.new
        op.runner = self
        op.settings = settings if settings != UNDEFINED

        @instance = op
      end

      # This is just here to raise a meaningful error.
      # @!visibility private
      def with(*)
        raise Teckel::Error, "Operation already has settings assigned."
      end

      # Halt any further execution with a output value
      #
      # @return a thing matching your {Teckel::Operation::Config#output output} definition
      # @!visibility protected
      def success!(*args)
        value =
          if args.size == 1 && operation.output === args.first # rubocop:disable Style/CaseEquality
            args.first
          else
            operation.output_constructor.call(*args)
          end

        throw :halt, instance.instance_exec(value, true, &operation.result_constructor)
      end

      # Halt any further execution with an error value
      #
      # @return a thing matching your {Teckel::Operation::Config#error error} definition
      # @!visibility protected
      def fail!(*args)
        value =
          if args.size == 1 && operation.error === args.first # rubocop:disable Style/CaseEquality
            args.first
          else
            operation.error_constructor.call(*args)
          end

        throw :halt, instance.instance_exec(value, false, &operation.result_constructor)
      end
    end
  end
end
