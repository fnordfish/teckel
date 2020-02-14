# frozen_string_literal: true

module Teckel
  module Operation
    module Config
      # @overload input()
      #   Get the configured class wrapping the input data structure.
      #   @return [Class] The +input+ class
      # @overload input(klass)
      #   Set the class wrapping the input data structure.
      #   @param  klass [Class] The +input+ class
      #   @return [Class] The +input+ class
      def input(klass = nil)
        @config.for(:input, klass) { self::Input if const_defined?(:Input) } ||
          raise(Teckel::MissingConfigError, "Missing input config for #{self}")
      end

      # @overload input_constructor()
      #   The callable constructor to build an instance of the +input+ class.
      #   Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #   @return [Proc] A callable that will return an instance of the +input+ class.
      #
      # @overload input_constructor(sym_or_proc)
      #   Define how to build the +input+.
      #   @param  sym_or_proc [Symbol, #call]
      #     - Either a +Symbol+ representing the _public_ method to call on the +input+ class.
      #     - Or anything that response to +#call+ (like a +Proc+).
      #   @return [#call] The callable constructor
      #
      #   @example simple symbol to method constructor
      #     class MyOperation
      #       include Teckel::Operation
      #
      #       class Input
      #         def initialize(name:, age:); end
      #       end
      #
      #       # If you need more control over how to build a new +Input+ instance
      #       # MyOperation.call(name: "Bob", age: 23) # -> Input.new(name: "Bob", age: 23)
      #       input_constructor :new
      #     end
      #
      #     MyOperation.input_constructor.is_a?(Method) #=> true
      #
      #   @example Custom Proc constructor
      #     class MyOperation
      #       include Teckel::Operation
      #
      #       class Input
      #         def initialize(*args, **opts); end
      #       end
      #
      #       # If you need more control over how to build a new +Input+ instance
      #       # MyOperation.call("foo", opt: "bar") # -> Input.new(name: "foo", opt: "bar")
      #       input_constructor ->(name, options) { Input.new(name: name, **options) }
      #     end
      #
      #     MyOperation.input_constructor.is_a?(Proc) #=> true
      def input_constructor(sym_or_proc = nil)
        get_set_counstructor(:input_constructor, input, sym_or_proc) ||
          raise(MissingConfigError, "Missing input_constructor config for #{self}")
      end

      # @overload output()
      #  Get the configured class wrapping the output data structure.
      #  Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #  @return [Class] The +output+ class
      #
      # @overload output(klass)
      #   Set the class wrapping the output data structure.
      #   @param  klass [Class] The +output+ class
      #   @return [Class] The +output+ class
      def output(klass = nil)
        @config.for(:output, klass) { self::Output if const_defined?(:Output) } ||
          raise(Teckel::MissingConfigError, "Missing output config for #{self}")
      end

      # @overload output_constructor()
      #  The callable constructor to build an instance of the +output+ class.
      #  Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #  @return [Proc] A callable that will return an instance of +output+ class.
      #
      # @overload output_constructor(sym_or_proc)
      #   Define how to build the +output+.
      #   @param sym_or_proc [Symbol, #call]
      #     - Either a +Symbol+ representing the _public_ method to call on the +output+ class.
      #     - Or anything that response to +#call+ (like a +Proc+).
      #   @return [#call] The callable constructor
      #
      #   @example
      #     class MyOperation
      #       include Teckel::Operation
      #
      #       class Output
      #         def initialize(*args, **opts); end
      #       end
      #
      #       # MyOperation.call("foo", "bar") # -> Output.new("foo", "bar")
      #       output_constructor :new
      #
      #       # If you need more control over how to build a new +Output+ instance
      #       # MyOperation.call("foo", opt: "bar") # -> Output.new(name: "foo", opt: "bar")
      #       output_constructor ->(name, options) { Output.new(name: name, **options) }
      #     end
      def output_constructor(sym_or_proc = nil)
        get_set_counstructor(:output_constructor, output, sym_or_proc) ||
          raise(MissingConfigError, "Missing output_constructor config for #{self}")
      end

      # @overload error()
      #   Get the configured class wrapping the error data structure.
      #   @return [Class] The +error+ class
      #
      # @overload error(klass)
      #   Set the class wrapping the error data structure.
      #   @param klass [Class] The +error+ class
      #   @return [Class,nil] The +error+ class or +nil+ if it does not error
      def error(klass = nil)
        @config.for(:error, klass) { self::Error if const_defined?(:Error) } ||
          raise(Teckel::MissingConfigError, "Missing error config for #{self}")
      end

      # @overload error_constructor()
      #   The callable constructor to build an instance of the +error+ class.
      #   Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #   @return [Proc] A callable that will return an instance of +error+ class.
      #
      # @overload error_constructor(sym_or_proc)
      #   Define how to build the +error+.
      #   @param sym_or_proc [Symbol, #call]
      #     - Either a +Symbol+ representing the _public_ method to call on the +error+ class.
      #     - Or anything that response to +#call+ (like a +Proc+).
      #   @return [#call] The callable constructor
      #
      #   @example
      #     class MyOperation
      #       include Teckel::Operation
      #
      #       class Error
      #         def initialize(*args, **opts); end
      #       end
      #
      #       # MyOperation.call("foo", "bar") # -> Error.new("foo", "bar")
      #       error_constructor :new
      #
      #       # If you need more control over how to build a new +Error+ instance
      #       # MyOperation.call("foo", opt: "bar") # -> Error.new(name: "foo", opt: "bar")
      #       error_constructor ->(name, options) { Error.new(name: name, **options) }
      #     end
      def error_constructor(sym_or_proc = nil)
        get_set_counstructor(:error_constructor, error, sym_or_proc) ||
          raise(MissingConfigError, "Missing error_constructor config for #{self}")
      end

      # @!endgroup

      # @overload settings()
      #  Get the configured class wrapping the settings data structure.
      #  @return [Class] The +settings+ class, or {Teckel::Contracts::None} as default
      #
      # @overload settings(klass)
      #   Set the class wrapping the settings data structure.
      #   @param klass [Class] The +settings+ class
      #   @return [Class] The +settings+ class configured
      def settings(klass = nil)
        @config.for(:settings, klass) { const_defined?(:Settings) ? self::Settings : none }
      end

      # @overload settings_constructor()
      #   The callable constructor to build an instance of the +settings+ class.
      #   Defaults to {Teckel::DEFAULT_CONSTRUCTOR}
      #   @return [Proc] A callable that will return an instance of +settings+ class.
      #
      # @overload settings_constructor(sym_or_proc)
      #  Define how to build the +settings+.
      #  @param  sym_or_proc [Symbol, #call]
      #    - Either a +Symbol+ representing the _public_ method to call on the +settings+ class.
      #    - Or anything that response to +#call+ (like a +Proc+).
      #  @return [#call] The callable constructor
      #
      #  @example
      #    class MyOperation
      #      include Teckel::Operation
      #
      #      class Settings
      #        def initialize(*args); end
      #      end
      #
      #      # MyOperation.with("foo", "bar") # -> Settings.new("foo", "bar")
      #      settings_constructor :new
      #    end
      def settings_constructor(sym_or_proc = nil)
        get_set_counstructor(:settings_constructor, settings, sym_or_proc) ||
          raise(MissingConfigError, "Missing settings_constructor config for #{self}")
      end

      # @overload runner()
      #   @return [Class] The Runner class
      #   @!visibility protected
      #
      # @overload runner(klass)
      #   Overwrite the default runner
      #   @param klass [Class] A class like the {Runner}
      #   @!visibility protected
      def runner(klass = nil)
        @config.for(:runner, klass) { Teckel::Operation::Runner }
      end

      # @overload result()
      #   Get the configured result object class wrapping {error} or {output}.
      #   The {ValueResult} default will act as a pass-through and does. Any error
      #   or output will just returned as-is.
      #   @return [Class] The +result+ class, or {ValueResult} as default
      #
      # @overload result(klass)
      #   Set the result object class wrapping {error} or {output}.
      #   @param klass [Class] The +result+ class
      #   @return [Class] The +result+ class configured
      def result(klass = nil)
        @config.for(:result, klass) { const_defined?(:Result, false) ? self::Result : ValueResult }
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
      #      class Result
      #        include Teckel::Result
      #        def initialize(value, success, opts = {}); end
      #      end
      #
      #      # If you need more control over how to build a new +Settings+ instance
      #      result_constructor ->(value, success) { result.new(value, success, {foo: :bar}) }
      #    end
      def result_constructor(sym_or_proc = nil)
        get_set_counstructor(:result_constructor, result, sym_or_proc) ||
          raise(MissingConfigError, "Missing result_constructor config for #{self}")
      end

      # @!group Shortcuts

      # Shortcut to use {Teckel::Operation::Result} as a result object,
      # wrapping any {error} or {output}.
      #
      # @!visibility protected
      # @note Don't use in conjunction with {result} or {result_constructor}
      # @return [nil]
      def result!
        @config.for(:result, Teckel::Operation::Result)
        @config.for(:result_constructor, Teckel::Operation::Result.method(:new))
        nil
      end

      # @!visibility private
      REQUIRED_CONFIGS = %i[
        input input_constructor
        output output_constructor
        error error_constructor
        settings settings_constructor
        result result_constructor
        runner
      ].freeze

      # @!visibility private
      # @return [void]
      def define!
        REQUIRED_CONFIGS.each { |e| public_send(e) }
        nil
      end

      # Disallow any further changes to this Operation.
      # Make sure all configurations are set.
      #
      # @raise [MissingConfigError]
      # @return [self] Frozen self
      # @!visibility public
      def finalize!
        define!
        @config.freeze
        self
      end

      # Produces a shallow copy of this operation and all it's configuration.
      #
      # @return [self]
      # @!visibility public
      def dup
        super.tap do |copy|
          copy.instance_variable_set(:@config, @config.dup)
        end
      end

      # Produces a clone of this operation and all it's configuration
      #
      # @return [self]
      # @!visibility public
      def clone
        if frozen?
          super
        else
          super.tap do |copy|
            copy.instance_variable_set(:@config, @config.dup)
          end
        end
      end

      # @!visibility private
      def inherited(subclass)
        subclass.instance_variable_set(:@config, @config.dup)
      end

      # @!visibility private
      def self.extended(base)
        base.instance_exec do
          @config = Teckel::Config.new
          attr_accessor :settings
        end
      end

      private

      def get_set_counstructor(name, on, sym_or_proc)
        constructor = build_counstructor(on, sym_or_proc) unless sym_or_proc.nil?

        @config.for(name, constructor) {
          build_counstructor(on, Teckel::DEFAULT_CONSTRUCTOR)
        }
      end

      def build_counstructor(on, sym_or_proc)
        if sym_or_proc.is_a?(Symbol) && on.respond_to?(sym_or_proc)
          on.public_method(sym_or_proc)
        elsif sym_or_proc.respond_to?(:call)
          sym_or_proc
        end
      end
    end
  end
end
