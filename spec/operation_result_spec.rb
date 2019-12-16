# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Waldi::Operation::Results do
  module WaldiOperationResultsTest
    class CreateUser
      include Waldi::Operation::Results

      input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
      output Types.Instance(User)
      error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

      # @param [Hash<name: String, age: Integer>]
      # @return [User | Hash<message: String, errors: [Hash]>]
      def call(input)
        user = User.new(name: input[:name], age: input[:age])
        if user.safe
          success! user
        else
          fail!(message: "Could not safe User", errors: user.errors)
        end
      end
    end
  end

  specify "output" do
    expect(WaldiOperationResultsTest::CreateUser.call(name: "Bob", age: 23).success).to be_a(User)
  end

  specify "errors" do
    expect(WaldiOperationResultsTest::CreateUser.call(name: "Bob", age: 10).failure).to eq(message: "Could not safe User", errors: [{ age: "underage" }])
  end
end
