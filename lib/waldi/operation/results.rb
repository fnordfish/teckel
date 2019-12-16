# frozen_string_literal: true

module Waldi
  module Operation
    # Works just like +Waldi::Operation+, but wraps +output+ and +error+ into a +Waldi::Result+.
    #
    # A +Waldi::Result+ given as +input+ will get unwrapped, so that the original +value+
    # gets passed to your Operation code.
    #
    # @example
    #
    #   class CreateUser
    #     include Waldi::Operation::Results
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
    #   CreateUser.call(name: "Bob", age: 23).is_a?(Waldi::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 23).success.is_a?(User) #=> true
    #
    #   # A failure call:
    #   CreateUser.call(name: "Bob", age: 10).is_a?(Waldi::Result) #=> true
    #   CreateUser.call(name: "Bob", age: 10).failure.is_a?(Hash) #=> true
    #
    #   # Unwrapping success input:
    #   CreateUser.call(Waldi::Result.new({name: "Bob", age: 23}, true)).success.is_a?(User) #=> true
    #
    #   # Unwrapping failure input:
    #   CreateUser.call(Waldi::Result.new({name: "Bob", age: 23}, false)).success.is_a?(User) #=> true
    #
    # @api public
    module Results
      module InstanceMethods
        private

        def build_input(input)
          input = input.value if input.is_a?(Waldi::Result)
          super(input)
        end

        def build_output(*args)
          Waldi::Result.new(super, true)
        end

        def build_error(*args)
          Waldi::Result.new(super, false)
        end
      end

      def self.included(receiver)
        receiver.send :include, Waldi::Operation unless Waldi::Operation >= receiver
        receiver.send :include, InstanceMethods
      end
    end
  end
end
