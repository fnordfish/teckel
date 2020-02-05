# frozen_string_literal: true

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

      # Declare a {Operation} as a named step
      #
      # @param name [String,Symbol] The name of the operation.
      #   This name is used in an error case to let you know which step failed.
      # @param operation [Operation] The operation to call, which
      #   must return a {Teckel::Result} object.
      def step(name, operation)
        steps << Step.new(name, operation)
      end

      # Get the list of defined steps
      #
      # @return [<Step>]
      def steps
        @config.for(:steps) { [] }
      end

      # Set or get the optional around hook.
      # A Hook might be given as a block or anything callable. The execution of
      # the chain is yielded to this hook. The first argument being the callable
      # chain ({Runner}) and the second argument the +input+ data. The hook also
      # needs to return the result.
      #
      # @param callable [Proc,{#call}] The hook to pass chain execution control to. (nil)
      #
      # @return [Proc,{#call}] The configured hook
      #
      # @example Around hook with block
      #   OUTPUTS = []
      #
      #   class Echo
      #     include ::Teckel::Operation
      #     result!
      #
      #     input Hash
      #     output input
      #
      #     def call(hsh)
      #       hsh
      #     end
      #   end
      #
      #   class MyChain
      #     include Teckel::Chain
      #
      #     around do |chain, input|
      #       OUTPUTS << "before start"
      #       result = chain.call(input)
      #       OUTPUTS << "after start"
      #       result
      #     end
      #
      #     step :noop, Echo
      #   end
      #
      #   result = MyChain.call(some: 'test')
      #   OUTPUTS #=> ["before start", "after start"]
      #   result.success #=> { some: "test" }
      def around(callable = nil, &block)
        @config.for(:around, callable || block)
      end

      # @!attribute [r] runner()
      # @return [Class] The Runner class
      # @!visibility protected

      # Overwrite the default runner
      # @param klass [Class] A class like the {Runner}
      # @!visibility protected
      def runner(klass = nil)
        @config.for(:runner, klass) { Runner }
      end

      # @overload result()
      #   Get the configured result object class wrapping {.error} or {.output}.
      #   @return [Class] The +result+ class, or {Teckel::Chain::Result} as default
      #
      # @overload result(klass)
      #   Set the result object class wrapping {.error} or {.output}.
      #   @param klass [Class] The +result+ class
      #   @return [Class] The +result+ class configured
      def result(klass = nil)
        @config.for(:result, klass) { const_defined?(:Result, false) ? self::Result : Teckel::Chain::Result }
      end

      # @overload result_constructor()
      #   The callable constructor to build an instance of the +result+ class.
      #   Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #   @return [Proc] A callable that will return an instance of +result+ class.
      #
      # @overload result_constructor(sym_or_proc)
      #  Define how to build the +result+.
      #  @param  sym_or_proc [Symbol, #call]
      #    - Either a +Symbol+ representing the _public_ method to call on the +result+ class.
      #    - Or anything that response to +#call+ (like a +Proc+).
      #  @return [#call] The callable constructor
      #
      #  @example
      #    class MyOperation
      #      include Teckel::Operation
      #
      #      class Result < Teckel::Operation::Result
      #        def initialize(value, success, step, options = {}); end
      #      end
      #
      #      # If you need more control over how to build a new +Settings+ instance
      #      result_constructor ->(value, success, step) { result.new(value, success, step, {foo: :bar}) }
      #    end
      def result_constructor(sym_or_proc = nil)
        constructor = build_counstructor(result, sym_or_proc) unless sym_or_proc.nil?

        @config.for(:result_constructor, constructor) {
          build_counstructor(result, Teckel::DEFAULT_CONSTRUCTOR)
        } || raise(MissingConfigError, "Missing result_constructor config for #{self}")
      end

      # The primary interface to call the chain with the given input.
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Chain::Result] The result object wrapping
      #   the result value, the success state and last executed step.
      def call(input = nil)
        runner = self.runner.new(self)
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

      # @!visibility private
      # @return [void]
      def define!
        raise MissingConfigError, "Cannot define Chain with no steps" if steps.empty?

        %i[around runner result result_constructor].each { |e| public_send(e) }
        steps.each(&:finalize!)
        nil
      end

      # Prevents further modifications to this Class and it's configuration
      # @return [self] Frozen self
      # @!visibility public
      def freeze
        steps.freeze
        @config.freeze
        super
      end

      # Disallow any further changes to this Chain.
      # @note This also calls +finalize!+ on all Operations defined as steps.
      #
      # @return [self] Frozen self
      # @!visibility public
      def finalize!
        define!
        freeze
      end

      # Produces a shallow copy of this chain.
      # It's {around}, {runner} and {steps} will get +dup+'ed
      #
      # @return [self]
      # @!visibility public
      def dup
        dup_config(super)
      end

      # Produces a clone of this chain.
      # It's {around}, {runner} and {steps} will get +dup+'ed
      #
      # @return [self]
      # @!visibility public
      def clone
        if frozen?
          super
        else
          dup_config(super)
        end
      end

      # @!visibility private
      def inherited(subclass)
        dup_config(subclass)
      end

      # @!visibility private
      def self.extended(base)
        base.instance_variable_set(:@config, Config.new)
      end

      private

      def dup_config(other_class)
        new_config = @config.dup
        new_config.replace(:steps) { steps.dup }

        other_class.instance_variable_set(:@config, new_config)
        other_class
      end

      def build_counstructor(on, sym_or_proc)
        if sym_or_proc.is_a?(Symbol) && on.respond_to?(sym_or_proc)
          on.public_method(sym_or_proc)
        elsif sym_or_proc.respond_to?(:call)
          sym_or_proc
        end
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end
