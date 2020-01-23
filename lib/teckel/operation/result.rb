# frozen_string_literal: true

module Teckel
  module Operation
    # The optional, default result object for {Teckel::Operation}s.
    # Wraps +output+ and +error+ into a {Teckel::Operation::Result}.
    #
    # @example
    #   class CreateUser
    #     include Teckel::Operation
    #
    #     result!    # Shortcut to use this Result object
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
    #   CreateUser.call(name: "Bob", age: 23).is_a?(Teckel::Operation::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 23).success.is_a?(User) #=> true
    #
    #   # A failure call:
    #   CreateUser.call(name: "Bob", age: 10).is_a?(Teckel::Operation::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 10).failure.is_a?(Hash) #=> true
    #
    # @!visibility public
    class Result
      include Teckel::Result

      # @param value [Object] The result value
      # @param success [Boolean] whether this is a successful result
      def initialize(value, success)
        @value = value
        @success = (!!success).freeze
      end

      # Whether this is a success result
      # @return [Boolean]
      def successful?
        @success
      end

      # @!attribute [r] value
      # @return [Mixed] the value/payload
      attr_reader :value

      # Get the error/failure value
      # @yield [Mixed] If a block is given and this is not a failure result, the value is yielded to the block
      # @param  default [Mixed] return this default value if it's not a failure result
      # @return [Mixed] the value/payload
      def failure(default = nil, &block)
        return @value unless @success
        return yield(@value) if block

        default
      end

      # Get the success value
      # @yield [Mixed] If a block is given and this is not a success result, the value is yielded to the block
      # @param  default [Mixed] return this default value if it's not a success result
      # @return [Mixed] the value/payload
      def success(default = nil, &block)
        return @value if @success
        return yield(@value) if block

        default
      end
    end

    # The default "no-op" Result handler. Just returns the value, ignoring the
    # success state.
    module ValueResult
      class << self
        def [](value, *_)
          value
        end

        alias :new :[]
      end
    end
  end
end
