# frozen_string_literal: true

module Teckel
  module Chain
    module Config
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
      # @param callable [Proc,#call] The hook to pass chain execution control to. (nil)
      #
      # @return [Proc,#call] The configured hook
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
      #       success!(hsh)
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
      #      result!
      #
      #      settings Struct.new(:say, :other)
      #      settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) }
      #
      #      input none
      #      output Hash
      #      error none
      #
      #      def call(_)
      #        success!(settings.to_h)
      #      end
      #    end
      #
      #    class Chain
      #      include Teckel::Chain
      #
      #      class Result < Teckel::Operation::Result
      #        def initialize(value, success, step, opts = {})
      #          super(value, success)
      #          @step = step
      #          @opts = opts
      #        end
      #
      #        class << self
      #          alias :[] :new # Alias the default constructor to :new
      #        end
      #
      #        attr_reader :opts, :step
      #      end
      #
      #      result_constructor ->(value, success, step) {
      #        result.new(value, success, step, time: Time.now.to_i)
      #      }
      #
      #      step :a, MyOperation
      #    end
      def result_constructor(sym_or_proc = nil)
        constructor = build_constructor(result, sym_or_proc) unless sym_or_proc.nil?

        @config.for(:result_constructor, constructor) {
          build_constructor(result, Teckel::DEFAULT_CONSTRUCTOR)
        } || raise(MissingConfigError, "Missing result_constructor config for #{self}")
      end

      # Declare default settings operation in this chain should use when called without
      # {Teckel::Chain::ClassMethods#with #with}.
      #
      # Explicit call-time settings will *not* get merged with declared default setting.
      #
      # @param settings [Hash{(String,Symbol) => Object}] Set settings for a step by it's name
      #
      # @example
      #   class MyOperation
      #     include Teckel::Operation
      #     result!
      #
      #     settings Struct.new(:say, :other)
      #     settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) }
      #
      #     input none
      #     output Hash
      #     error none
      #
      #     def call(_)
      #       success!(settings.to_h)
      #     end
      #   end
      #
      #   class Chain
      #     include Teckel::Chain
      #
      #     default_settings!(a: { say: "Chain Default" })
      #
      #     step :a, MyOperation
      #   end
      #
      #   # Using the chains default settings
      #   result = Chain.call
      #   result.success #=> {say: "Chain Default", other: nil}
      #
      #   # explicit settings passed via `with` will overwrite all defaults
      #   result = Chain.with(a: { other: "What" }).call
      #   result.success #=> {say: nil, other: "What"}
      def default_settings!(settings) # :nodoc: The bang is for consistency with the Operation class
        @config.for(:default_settings, settings)
      end

      # Getter for configured default settings
      # @return [NilClass]
      # @return [#call] The callable constructor
      def default_settings
        @config.for(:default_settings)
      end

      # @!visibility private
      # @return [Array<Symbol>]
      REQUIRED_CONFIGS = %i[around runner result result_constructor].freeze

      # @!visibility private
      # @return [void]
      def define!
        raise MissingConfigError, "Cannot define Chain with no steps" if steps.empty?

        REQUIRED_CONFIGS.each { |e| public_send(e) }
        steps.each(&:finalize!)
        nil
      end

      # Disallow any further changes to this Chain.
      # @note This also calls +finalize!+ on all Operations defined as steps.
      #
      # @return [self] Frozen self
      # @!visibility public
      def finalize!
        define!
        steps.freeze
        @config.freeze
        self
      end

      # Produces a shallow copy of this chain.
      # It's {around}, {runner} and {steps} will get +dup+'ed
      #
      # @return [self]
      # @!visibility public
      def dup
        dup_config(super())
      end

      # Produces a clone of this chain.
      # It's {around}, {runner} and {steps} will get +dup+'ed
      #
      # @return [self]
      # @!visibility public
      def clone
        if frozen?
          super()
        else
          dup_config(super())
        end
      end

      # Prevents further modifications to this chain and its config
      #
      # @return [self]
      # @!visibility public
      def freeze
        steps.freeze
        @config.freeze
        super()
      end

      # @!visibility private
      def inherited(subclass)
        super(dup_config(subclass))
      end

      # @!visibility private
      def self.extended(base)
        base.instance_variable_set(:@config, Teckel::Config.new)
      end

      private

      def dup_config(other_class)
        new_config = @config.dup
        new_config.replace(:steps) { steps.dup }

        other_class.instance_variable_set(:@config, new_config)
        other_class
      end

      def build_constructor(on, sym_or_proc)
        case sym_or_proc
        when Proc
          sym_or_proc
        when Symbol
          on.public_method(sym_or_proc) if on.respond_to?(sym_or_proc)
        end
      end
    end
  end
end
