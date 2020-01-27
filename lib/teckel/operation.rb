# frozen_string_literal: true

require_relative "operation/result"
require_relative "operation/runner"

module Teckel
  # The main operation Mixin
  #
  # Each operation is expected to declare +input+. +output+ and +error+ classes.
  #
  # There are two ways of declaring those classes. The first way is to define
  # the constants +Input+, +Output+ and +Error+, the second way is to use the
  # +input+. +output+ and +error+ methods to point them to anonymous classes.
  #
  # If you like "traditional" result objects to ask +successful?+ or +failure?+ on,
  # use {.result!} and get {Teckel::Operation::Result}
  #
  # By default, +input+. +output+ and +error+ classes are build using +:[]+
  # (eg: +Input[some: :param]+).
  # Use {ClassMethods#input_constructor input_constructor},
  # {ClassMethods#output_constructor output_constructor} and
  # {ClassMethods#error_constructor error_constructor} to change them.
  #
  # @example class definitions via constants
  #   class CreateUserViaConstants
  #     include Teckel::Operation
  #
  #     class Input
  #       def initialize(name:, age:)
  #         @name, @age = name, age
  #       end
  #       attr_reader :name, :age
  #     end
  #
  #     Output = ::User
  #
  #     class Error
  #       def initialize(message, errors)
  #         @message, @errors = message, errors
  #       end
  #       attr_reader :message, :errors
  #     end
  #
  #     input_constructor :new
  #     error_constructor :new
  #
  #     # @param [CreateUser::Input]
  #     # @return [User,CreateUser::Error]
  #     def call(input)
  #       user = ::User.new(name: input.name, age: input.age)
  #       if user.save
  #         user
  #       else
  #         fail!(message: "Could not save User", errors: user.errors)
  #       end
  #     end
  #   end
  #
  #   CreateUserViaConstants.call(name: "Bob", age: 23).is_a?(User) #=> true
  #
  # @example class definitions via methods
  #   class CreateUserViaMethods
  #     include Teckel::Operation
  #
  #     input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
  #     output Types.Instance(User)
  #     error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
  #
  #     # @param [Hash<name: String, age: Integer>]
  #     # @return [User,Hash<message: String, errors: [Hash]>]
  #     def call(input)
  #       user = User.new(name: input[:name], age: input[:age])
  #       if user.save
  #         success!(user) # exits early with success, prevents any further execution
  #       else
  #         fail!(message: "Could not save User", errors: user.errors)
  #       end
  #     end
  #   end
  #
  #   # A success call:
  #   CreateUserViaMethods.call(name: "Bob", age: 23).is_a?(User) #=> true
  #
  #   # A failure call:
  #   CreateUserViaMethods.call(name: "Bob", age: 10).eql?(message: "Could not save User", errors: [{age: "underage"}]) #=> true
  #
  #   # Build your Input, Output and Error classes in a way that let you know:
  #   begin; CreateUserViaMethods.call(unwanted: "input"); rescue => e; e end.is_a?(::Dry::Types::MissingKeyError) #=> true
  #
  #   # Feed an instance of the input class directly to call:
  #   CreateUserViaMethods.call(CreateUserViaMethods.input[name: "Bob", age: 23]).is_a?(User) #=> true
  #
  # @!visibility public
  module Operation
    module ClassMethods
      # @!group Contacts definition

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
      #   Defaults to {Teckel::Config.default_constructor}
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
      #  Defaults to {Teckel::Config.default_constructor}
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
      #  Defaults to {Teckel::Config.default_constructor}
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
      #   Defaults to {Teckel::Config.default_constructor}
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
      #   Defaults to {Teckel::Config.default_constructor}
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
      #        def initialize(*args, **opts); end
      #      end
      #
      #      # MyOperation.with("foo", "bar") # -> Settings.new("foo", "bar")
      #      settings_constructor :new
      #
      #      # If you need more control over how to build a new +Settings+ instance
      #      # MyOperation.with("foo", opt: "bar") # -> Settings.new(name: "foo", opt: "bar")
      #      settings_constructor ->(name, options) { Settings.new(name: name, **options) }
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
      #   Defaults to {Teckel::Config.default_constructor}
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

      # Convenience method for setting {#input}, {#output} or {#error} to the
      # {Teckel::Contracts::None} value.
      # @return [Object] The {Teckel::Contracts::None} class.
      #
      # @example Enforcing nil input, output or error
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     input none
      #
      #     # same as
      #     output Teckel::Contracts::None
      #
      #     error none
      #
      #     def call(_) # you still need to take than +nil+ input when using `input none`
      #       # when using `error none`:
      #       # `fail!` works, but `fail!("data")` raises an error
      #
      #       # when using `output none`:
      #       # `success!` works, but `success!("data")` raises an error
      #       # same thing when using simple return values as success:
      #       # take care to not return anything
      #       nil
      #     end
      #   end
      #
      #   MyOperation.call #=> nil
      def none
        Teckel::Contracts::None
      end

      # @endgroup

      # Invoke the Operation
      #
      # @param input Any form of input your {#input} class can handle via the given {#input_constructor}
      # @return Either An instance of your defined {#error} class or {#output} class
      # @!visibility public
      def call(input = nil)
        runner.new(self).call(input)
      end

      # Provide {InstanceMethods#settings() settings} to the running operation.
      #
      # This method is intended to be called on the operation class outside of
      # it's definition, prior to running {#call}.
      #
      # @param input Any form of input your {#settings} class can handle via the given {#settings_constructor}
      # @return [Class] The configured {runner}
      # @!visibility public
      #
      # @example Inject settings for an operation call
      #   LOG = []
      #
      #   class MyOperation
      #     include ::Teckel::Operation
      #
      #     settings Struct.new(:log)
      #
      #     input none
      #     output none
      #     error none
      #
      #     def call(_input)
      #       settings.log << "called" if settings&.log
      #       nil
      #     end
      #   end
      #
      #   MyOperation.with(LOG).call
      #   LOG #=> ["called"]
      #
      #   LOG.clear
      #
      #   MyOperation.with(false).call
      #   MyOperation.call
      #   LOG #=> []
      def with(input)
        runner.new(self, settings_constructor.call(input))
      end
      alias :set :with

      # @!visibility private
      # @return [void]
      def define!
        %i[
          input input_constructor
          output output_constructor
          error error_constructor
          settings settings_constructor
          result result_constructor
          runner
        ].each { |e| public_send(e) }
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
        freeze
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

      private

      def get_set_counstructor(name, on, sym_or_proc)
        constructor = build_counstructor(on, sym_or_proc) unless sym_or_proc.nil?

        @config.for(name, constructor) {
          build_counstructor(on, Config.default_constructor)
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

    module InstanceMethods
      # @!attribute [r] settings()
      # @return [Class,nil] When executed with settings, an instance of the
      #   configured {.settings} class. Otherwise +nil+
      # @see ClassMethods#settings
      # @!visibility public

      # Halt any further execution with a output value
      #
      # @return a thing matching your {Operation::ClassMethods#output Operation#output} definition
      # @!visibility protected
      def success!(*args)
        throw :success, args
      end

      # Halt any further execution with an error value
      #
      # @return a thing matching your {Operation::ClassMethods#error Operation#error} definition
      # @!visibility protected
      def fail!(*args)
        throw :failure, args
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        @config = Config.new
        attr_accessor :settings
        protected :success!, :fail!

        result! if Teckel::Config.results?
      end
    end
  end
end
