# frozen_string_literal: true

require_relative "operation/config"
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
      receiver.extend         Config
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
