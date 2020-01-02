# frozen_string_literal: true

module Teckel
  module Operation
    # Works just like {Teckel::Operation}, but wraps +output+ and +error+ into a
    # {Teckel::Result Teckel::Result}.
    #
    # If a {Teckel::Result Teckel::Result} is given as +input+, it will get unwrapped,
    # so that the original {Teckel::Result#value} gets passed to your Operation code.
    #
    # @example
    #
    #   class CreateUser
    #     include Teckel::Operation::Results
    #
    #     input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
    #     output Types.Instance(User)
    #     error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
    #
    #     # @param [Hash<name: String, age: Integer>]
    #     # @return [User,Hash<message: String, errors: [Hash]>]
    #     def call(input)
    #       user = User.new(name: input[:name], age: input[:age])
    #       if user.safe
    #         success!(user) # exits early with success, prevents any further execution
    #       else
    #         fail!(message: "Could not safe User", errors: user.errors)
    #       end
    #     end
    #   end
    #
    #   # A success call:
    #   CreateUser.call(name: "Bob", age: 23).is_a?(Teckel::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 23).success.is_a?(User) #=> true
    #
    #   # A failure call:
    #   CreateUser.call(name: "Bob", age: 10).is_a?(Teckel::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 10).failure.is_a?(Hash) #=> true
    #
    #   # Unwrapping success input:
    #   CreateUser.call(Teckel::Result.new({name: "Bob", age: 23}, true)).success.is_a?(User) #=> true
    #
    #   # Unwrapping failure input:
    #   CreateUser.call(Teckel::Result.new({name: "Bob", age: 23}, false)).success.is_a?(User) #=> true
    #
    # @api public
    module Results
      module InstanceMethods
        private

        def build_input(input)
          input = input.value if input.is_a?(Teckel::Result)
          super(input)
        end

        def build_output(*args)
          Teckel::Result.new(super, true)
        end

        def build_error(*args)
          Teckel::Result.new(super, false)
        end
      end

      def self.included(receiver)
        receiver.send :include, Teckel::Operation unless Teckel::Operation >= receiver
        receiver.send :include, InstanceMethods
      end
    end
  end
end
