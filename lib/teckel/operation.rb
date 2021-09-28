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
  # use {Teckel::Operation::Config#result! result!} and get {Teckel::Operation::Result}
  #
  # By default, +input+. +output+ and +error+ classes are build using +:[]+
  # (eg: +Input[some: :param]+).
  #
  # Use {Teckel::Operation::Config#input_constructor input_constructor},
  # {Teckel::Operation::Config#output_constructor output_constructor} and
  # {Teckel::Operation::Config#error_constructor error_constructor} to change them.
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
      # @!visibility private
      UNDEFINED = Object.new

      # Invoke the Operation
      #
      # @param input Any form of input your {Teckel::Operation::Config#input input} class can handle via the given
      #   {Teckel::Operation::Config#input_constructor input_constructor}
      # @return Either An instance of your defined {Teckel::Operation::Config#error error} class or
      #   {Teckel::Operation::Config#output output} class
      # @!visibility public
      def call(input = nil)
        runable.call(input)
      end

      # Provide {InstanceMethods#settings() settings} to the operation.
      #
      # This method is intended to be called on the operation class outside of
      # it's definition, prior to invoking {#call}.
      #
      # @param settings Any form of settings your {Teckel::Operation::Config#settings settings} class can handle via the given
      #   {Teckel::Operation::Config#settings_constructor settings_constructor}
      # @return [Class] The configured {Teckel::Operation::Config#runner runner}
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
      def with(settings)
        runable(settings_constructor.call(settings))
      end
      alias :set :with

      # Constructs a Runner instance for {call} and {with}.
      #
      # @note This method is public to make testing, stubbing and mocking easier.
      #   Your normal application code should use {with} and/or {call}
      #
      # @param settings Optional. Any form of settings your
      #   {Teckel::Operation::Config#settings settings} class can handle via the
      #   given {Teckel::Operation::Config#settings_constructor settings_constructor}
      # @return [Class] The configured {Teckel::Operation::Config#runner runner}
      # @!visibility public
      def runable(settings = UNDEFINED)
        if settings != UNDEFINED
          runner.new(self, settings)
        elsif default_settings
          runner.new(self, default_settings.call)
        else
          runner.new(self)
        end
      end

      # Convenience method for setting {Teckel::Operation::Config#input input},
      # {Teckel::Operation::Config#output output} or
      # {Teckel::Operation::Config#error error} to the
      # {Teckel::Contracts::None} value.
      #
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
      #     end
      #   end
      #
      #   MyOperation.call #=> nil
      def none
        Contracts::None
      end
    end

    module InstanceMethods
      # @!method call(input)
      # @abstract
      # @see Operation
      # @see ClassMethods#call
      #
      # The entry point for your operation. It needs to always accept an input value, even when
      # using +input none+.
      # If your Operation expects to generate success or failure outputs, you need to use either
      # {.success!} or {.fail!} respectively. Simple return values will get ignored by default. See
      # {Teckel::Operation::Config#runner} and {Teckel::Operation::Runner} on how to overwrite.

      # @!attribute [r] settings()
      # @return [Class,nil] When executed with settings, an instance of the
      #   configured {.settings} class. Otherwise +nil+
      # @see ClassMethods#settings
      # @!visibility public

      # Delegates to the configured Runner.
      # The default behavior is to halt any further execution with a output value.
      #
      # @see Teckel::Operation::Runner#success!
      # @!visibility protected
      def success!(*args)
        runner.success!(*args)
      end

      # Delegates to the configured Runner.
      # The default behavior is to halt any further execution with an error value.
      #
      # @see Teckel::Operation::Runner#fail!
      # @!visibility protected
      def fail!(*args)
        runner.fail!(*args)
      end
    end

    def self.included(receiver)
      receiver.class_eval do
        extend  Config
        extend  ClassMethods
        include InstanceMethods
      end
    end
  end
end
