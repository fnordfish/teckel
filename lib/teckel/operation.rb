# frozen_string_literal: true

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
  # see {Teckel::Operation::Results Teckel::Operation::Results}
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
    # The default implementation for executing a single {Operation}
    #
    # @!visibility protected
    class Runner
      # @!visibility private
      UNDEFINED = Object.new.freeze

      def initialize(operation)
        @operation = operation
      end
      attr_reader :operation

      def call(input)
        err = catch(:failure) do
          simple_return = UNDEFINED
          out = catch(:success) do
            simple_return = @operation.new.call(build_input(input))
          end
          return simple_return == UNDEFINED ? build_output(*out) : build_output(simple_return)
        end
        build_error(*err)
      end

      private

      def build_input(input)
        operation.input_constructor.call(input)
      end

      def build_output(*args)
        if args.size == 1 && operation.output === args.first # rubocop:disable Style/CaseEquality
          args.first
        else
          operation.output_constructor.call(*args)
        end
      end

      def build_error(*args)
        if args.size == 1 && operation.error === args.first # rubocop:disable Style/CaseEquality
          args.first
        else
          operation.error_constructor.call(*args)
        end
      end
    end

    module ClassMethods
      # @!attribute [r] input()
      # Get the configured class wrapping the input data structure.
      # @return [Class] The +input+ class

      # @!method input(klass)
      # Set the class wrapping the input data structure.
      # @param  klass [Class] The +input+ class
      # @return [Class] The +input+ class
      def input(klass = nil)
        @config.for(:input, klass) { self::Input if const_defined?(:Input) } ||
          raise(Teckel::MissingConfigError, "Missing input config for #{self}")
      end

      # @!attribute [r] input_constructor()
      # The callable constructor to build an instance of the +input+ class.
      # @return [Class] The Input class

      # @!method input_constructor(sym_or_proc)
      # Define how to build the +input+.
      # @param  sym_or_proc [Symbol, #call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +input+ class.
      #   - Or anything that response to +#call+ (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example simple symbol to method constructor
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Input
      #       def initialize(name:, age:); end
      #     end
      #
      #     # If you need more control over how to build a new +Input+ instance
      #     # MyOperation.call(name: "Bob", age: 23) # -> Input.new(name: "Bob", age: 23)
      #     input_constructor :new
      #   end
      #
      #   MyOperation.input_constructor.is_a?(Method) #=> true
      #
      # @example Custom Proc constructor
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Input
      #       def initialize(*args, **opts); end
      #     end
      #
      #     # If you need more control over how to build a new +Input+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Input.new(name: "foo", opt: "bar")
      #     input_constructor ->(name, options) { Input.new(name: name, **options) }
      #   end
      #
      #   MyOperation.input_constructor.is_a?(Proc) #=> true
      def input_constructor(sym_or_proc = Config.default_constructor)
        @config.for(:input_constructor) { build_counstructor(input, sym_or_proc) } ||
          raise(MissingConfigError, "Missing input_constructor config for #{self}")
      end

      # @!attribute [r] output()
      # Get the configured class wrapping the output data structure.
      # @return [Class] The +output+ class

      # @!method output(klass)
      # Set the class wrapping the output data structure.
      # @param  klass [Class] The +output+ class
      # @return [Class] The +output+ class
      def output(klass = nil)
        @config.for(:output, klass) { self::Output if const_defined?(:Output) } ||
          raise(Teckel::MissingConfigError, "Missing output config for #{self}")
      end

      # @!attribute [r] output_constructor()
      # The callable constructor to build an instance of the +output+ class.
      # @return [Class] The Output class

      # @!method output_constructor(sym_or_proc)
      # Define how to build the +output+.
      # @param  sym_or_proc [Symbol, #call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +output+ class.
      #   - Or anything that response to +#call+ (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Output
      #       def initialize(*args, **opts); end
      #     end
      #
      #     # MyOperation.call("foo", "bar") # -> Output.new("foo", "bar")
      #     output_constructor :new
      #
      #     # If you need more control over how to build a new +Output+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Output.new(name: "foo", opt: "bar")
      #     output_constructor ->(name, options) { Output.new(name: name, **options) }
      #   end
      def output_constructor(sym_or_proc = Config.default_constructor)
        @config.for(:output_constructor) { build_counstructor(output, sym_or_proc) } ||
          raise(MissingConfigError, "Missing output_constructor config for #{self}")
      end

      # @!attribute [r] error()
      # Get the configured class wrapping the error data structure.
      # @return [Class] The +error+ class

      # @!method error(klass)
      # Set the class wrapping the error data structure.
      # @param  klass [Class] The +error+ class
      # @return [Class,nil] The +error+ class or +nil+ if it does not error
      def error(klass = nil)
        @config.for(:error, klass) { self::Error if const_defined?(:Error) } ||
          raise(Teckel::MissingConfigError, "Missing error config for #{self}")
      end

      # @!attribute [r] error_constructor()
      # The callable constructor to build an instance of the +error+ class.
      # @return [Class] The Error class

      # @!method error_constructor(sym_or_proc)
      # Define how to build the +error+.
      # @param  sym_or_proc [Symbol, #call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +error+ class.
      #   - Or anything that response to +#call+ (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Error
      #       def initialize(*args, **opts); end
      #     end
      #
      #     # MyOperation.call("foo", "bar") # -> Error.new("foo", "bar")
      #     error_constructor :new
      #
      #     # If you need more control over how to build a new +Error+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Error.new(name: "foo", opt: "bar")
      #     error_constructor ->(name, options) { Error.new(name: name, **options) }
      #   end
      def error_constructor(sym_or_proc = Config.default_constructor)
        @config.for(:error_constructor) { build_counstructor(error, sym_or_proc) } ||
          raise(MissingConfigError, "Missing error_constructor config for #{self}")
      end

      # Convenience method for setting {#input}, {#output} or {#error} to the {None} value.
      # @return [None]
      # @example Enforcing nil input, output or error
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     input none
      #
      #     # same as
      #     output Teckel::None
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
        None
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

      # Invoke the Operation
      #
      # @param input Any form of input your +input+ class can handle via the given +input_constructor+
      # @return Either An instance of your defined +error+ class or +output+ class
      # @!visibility public
      def call(input = nil)
        runner.new(self).call(input)
      end

      # @!visibility private
      # @return [nil]
      def define!
        %i[input input_constructor output output_constructor error error_constructor runner].each { |e|
          public_send(e)
        }
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

      # @!visibility public
      def dup
        super.tap do |copy|
          copy.instance_variable_set(:@config, @config.dup)
        end
      end

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

      def build_counstructor(on, sym_or_proc)
        if sym_or_proc.is_a?(Symbol) && on.respond_to?(sym_or_proc)
          on.public_method(sym_or_proc)
        elsif sym_or_proc.respond_to?(:call)
          sym_or_proc
        end
      end
    end

    module InstanceMethods
      # Halt any further execution with a +output+ value
      # @!visibility protected
      def success!(*args)
        throw :success, args
      end

      # Halt any further execution with an +error+ value
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

        protected :success!, :fail!
      end
    end
  end
end
