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
  # If you like "traditional" result objects (to ask +successful?+ or +failure?+ on)
  # see +Teckel::Operation::Results+
  #
  # @see Teckel::Operation::Results
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
  #     # @return [User | CreateUser::Error]
  #     def call(input)
  #       user = ::User.new(name: input.name, age: input.age)
  #       if user.safe
  #         user
  #       else
  #         fail!(message: "Could not safe User", errors: user.errors)
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
  #     # @return [User | Hash<message: String, errors: [Hash]>]
  #     def call(input)
  #       user = User.new(name: input[:name], age: input[:age])
  #       if user.safe
  #         # exits early with success, prevents any further execution
  #         success!(user)
  #       else
  #         fail!(message: "Could not safe User", errors: user.errors)
  #       end
  #     end
  #   end
  #
  #   # A success call:
  #   CreateUserViaMethods.call(name: "Bob", age: 23).is_a?(User) #=> true
  #
  #   # A failure call:
  #   CreateUserViaMethods.call(name: "Bob", age: 10).eql?(message: "Could not safe User", errors: [{age: "underage"}]) #=> true
  #
  #   # Build your Input, Output and Error classes in a way that let you know:
  #   begin; CreateUserViaMethods.call(unwanted: "input"); rescue => e; e end.is_a?(::Dry::Types::MissingKeyError) #=> true
  #
  #   # Feed an instance of the input class directly to call:
  #   CreateUserViaMethods.call(CreateUserViaMethods.input[name: "Bob", age: 23]).is_a?(User) #=> true
  #
  # @api public
  module Operation
    module ClassMethods
      # @!attribute [r] input()
      # Get the configured class wrapping the input data structure.
      # @return [Class] The +input+ class

      # @!method input(klass)
      # Set the class wrapping the input data structure.
      # @param  klass [Class] The +input+ class
      # @return [Class] The +input+ class
      def input(klass = nil)
        return @input_class if @input_class

        @input_class = @config.input(klass)
        @input_class ||= self::Input if const_defined?(:Input)
        @input_class
      end

      # @!attribute [r] input_constructor()
      # The callable constructor to build an instance of the +input+ class.
      # @return [Class] The Input class

      # @!method input_constructor(sym_or_proc)
      # Define how to build the +input+.
      # @param  sym_or_proc [Symbol|#call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +input+ class.
      #   - Or a callable (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example simple symbol to method constructor
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Input
      #       # ...
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
      #       # ...
      #     end
      #
      #     # If you need more control over how to build a new +Input+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Input.new(name: "foo", opt: "bar")
      #     input_constructor ->(name, options) { Input.new(name: name, **options) }
      #   end
      #
      #   MyOperation.input_constructor.is_a?(Proc) #=> true
      def input_constructor(sym_or_proc = nil)
        return @input_constructor if @input_constructor

        constructor = @config.input_constructor(sym_or_proc)
        @input_constructor =
          if constructor.is_a?(Symbol) && input.respond_to?(constructor)
            input.public_method(constructor)
          elsif sym_or_proc.respond_to?(:call)
            sym_or_proc
          end
      end

      # @!attribute [r] output()
      # Get the configured class wrapping the output data structure.
      # @return [Class] The +output+ class

      # @!method output(klass)
      # Set the class wrapping the output data structure.
      # @param  klass [Class] The +output+ class
      # @return [Class] The +output+ class
      def output(klass = nil)
        return @output_class if @output_class

        @output_class = @config.output(klass)
        @output_class ||= self::Output if const_defined?(:Output)
        @output_class
      end

      # @!attribute [r] output_constructor()
      # The callable constructor to build an instance of the +output+ class.
      # @return [Class] The Output class

      # @!method output_constructor(sym_or_proc)
      # Define how to build the +output+.
      # @param  sym_or_proc [Symbol|#call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +output+ class.
      #   - Or a callable (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Output
      #       # ....
      #     end
      #
      #     # MyOperation.call("foo", "bar") # -> Output.new("foo", "bar")
      #     output_constructor :new
      #
      #     # If you need more control over how to build a new +Output+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Output.new(name: "foo", opt: "bar")
      #     output_constructor ->(name, options) { Output.new(name: name, **options) }
      #   end
      def output_constructor(sym_or_proc = nil)
        return @output_constructor if @output_constructor

        constructor = @config.output_constructor(sym_or_proc)
        @output_constructor =
          if constructor.is_a?(Symbol) && output.respond_to?(constructor)
            output.public_method(constructor)
          elsif sym_or_proc.respond_to?(:call)
            sym_or_proc
          end
      end

      # @!attribute [r] error()
      # Get the configured class wrapping the error data structure.
      # @return [Class] The +error+ class

      # @!method error(klass)
      # Set the class wrapping the error data structure.
      # @param  klass [Class] The +error+ class
      # @return [Class] The +error+ class
      def error(klass = nil)
        return @error_class if @error_class

        @error_class = @config.error(klass)
        @error_class ||= self::Error if const_defined?(:Error)
        @error_class
      end

      # @!attribute [r] error_constructor()
      # The callable constructor to build an instance of the +error+ class.
      # @return [Class] The Error class

      # @!method error_constructor(sym_or_proc)
      # Define how to build the +error+.
      # @param  sym_or_proc [Symbol|#call]
      #   - Either a +Symbol+ representing the _public_ method to call on the +error+ class.
      #   - Or a callable (like a +Proc+).
      # @return [#call] The callable constructor
      #
      # @example
      #   class MyOperation
      #     include Teckel::Operation
      #
      #     class Error
      #       # ....
      #     end
      #
      #     # MyOperation.call("foo", "bar") # -> Error.new("foo", "bar")
      #     error_constructor :new
      #
      #     # If you need more control over how to build a new +Error+ instance
      #     # MyOperation.call("foo", opt: "bar") # -> Error.new(name: "foo", opt: "bar")
      #     error_constructor ->(name, options) { Error.new(name: name, **options) }
      #   end
      def error_constructor(sym_or_proc = nil)
        return @error_constructor if @error_constructor

        constructor = @config.error_constructor(sym_or_proc)
        @error_constructor =
          if constructor.is_a?(Symbol) && error.respond_to?(constructor)
            error.public_method(constructor)
          elsif sym_or_proc.respond_to?(:call)
            sym_or_proc
          end
      end

      # Invoke the Operation
      #
      # @param input Any form of input your +input+ class can handle via the given +input_constructor+
      # @return Either An instance of your defined +error+ class or +output+ class
      def call(input)
        new.call!(input)
      end
    end

    module InstanceMethods
      # @!visibility protected
      def call!(input)
        catch(:failure) do
          out = catch(:success) do
            simple_ret = call(build_input(input))
            build_output(simple_ret)
          end
          return out
        end
      end

      # @!visibility protected
      def success!(*args)
        throw :success, build_output(*args)
      end

      # @!visibility protected
      def fail!(*args)
        throw :failure, build_error(*args)
      end

      private

      def build_input(input)
        self.class.input_constructor.call(input)
      end

      def build_output(*args)
        if args.size == 1 && self.class.output === args.first # rubocop:disable Style/CaseEquality
          args.first
        else
          self.class.output_constructor.call(*args)
        end
      end

      def build_error(*args)
        if args.size == 1 && self.class.error === args.first # rubocop:disable Style/CaseEquality
          args.first
        else
          self.class.error_constructor.call(*args)
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        @config = Config.new

        @input_class = nil
        @input_constructor = nil

        @output_class = nil
        @output_constructor = nil

        @error_class = nil
        @error_constructor = nil

        protected :success!, :fail!
      end
    end
  end
end
