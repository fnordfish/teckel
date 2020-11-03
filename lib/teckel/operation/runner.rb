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
        catch(:failure) do
          out = catch(:success) do
            run operation.input_constructor.call(input)
            return nil # :sic!: return values need to go through +success!+
          end

          return out
        end
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

        throw :success, operation.result_constructor.call(value, true)
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

        throw :failure, operation.result_constructor.call(value, false)
      end

      private

      def run(input)
        op = @operation.new
        op.runner = self
        op.settings = settings if settings != UNDEFINED
        op.call(input)
      end
    end
  end
end
