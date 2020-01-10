# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Operation::Results do
  class CreateUserWithResult
    include Teckel::Operation::Results

    input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
    output Types.Instance(User)
    error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

    # @param [Hash<name: String, age: Integer>]
    # @return [User,Hash<message: String, errors: [Hash]>]
    def call(input)
      user = User.new(name: input[:name], age: input[:age])
      if user.save
        user
      else
        fail!(message: "Could not save User", errors: user.errors)
      end
    end
  end

  specify "output" do
    result = CreateUserWithResult.call(name: "Bob", age: 23)
    expect(result).to be_a(Teckel::Result)
    expect(result).to be_successful
    expect(result.success).to be_a(User)
  end

  specify "errors" do
    result = CreateUserWithResult.call(name: "Bob", age: 10)
    expect(result).to be_a(Teckel::Result)
    expect(result).to be_failure
    expect(result.failure).to eq(message: "Could not save User", errors: [{ age: "underage" }])
  end
end
