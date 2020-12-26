# frozen_string_literal: true

require "dry/validation"
require 'support/dry_base'
require 'support/fake_models'

module TeckelOperationFailOnOInput
  class NewUserContract < Dry::Validation::Contract
    schema do
      required(:name).filled(:string)
      required(:age).value(:integer)
    end
  end

  class CreateUser
    include Teckel::Operation

    result!

    input(->(input) { input }) # NoOp
    input_constructor(->(input){
      result = NewUserContract.new.call(input)
      if result.success?
        result.to_h
      else
        fail!(message: "Input data validation failed", errors: [result.errors.to_h])
      end
    })

    output Types.Instance(User)
    error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

    def call(input)
      user = User.new(name: input[:name], age: input[:age])
      if user.save
        success! user
      else
        fail!(message: "Could not save User", errors: user.errors)
      end
    end

    finalize!
  end

  class CreateUserIncorrectFailure
    include Teckel::Operation

    result!

    input(->(input) { input }) # NoOp
    input_constructor(->(_input) {
      fail!("Input data validation failed")
    })

    output none
    error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

    def call(_); end
    finalize!
  end
end

RSpec.describe Teckel::Operation do
  specify "successs" do
    result = TeckelOperationFailOnOInput::CreateUser.call(name: "Bob", age: 23)
    expect(result).to be_successful
    expect(result.success).to be_a(User)
  end

  describe "failing in input_constructor" do
    let(:failure_input) do
      { name: "", age: "incorrect type" }
    end

    it "returns the failure thrown in input_constructor" do
      result = TeckelOperationFailOnOInput::CreateUser.call(failure_input)
      expect(result).to be_a(Teckel::Operation::Result)
      expect(result).to be_failure
      expect(result.failure).to eq(
        message: "Input data validation failed",
        errors: [
          { name: ["must be filled"], age: ["must be an integer"] }
        ]
      )
    end

    it "does not run .call" do
      expect(TeckelOperationFailOnOInput::CreateUser).to receive(:new).and_wrap_original do |m, *args|
        op_instance = m.call(*args)
        expect(op_instance).to_not receive(:call)
        op_instance
      end

      TeckelOperationFailOnOInput::CreateUser.call(failure_input)
    end
  end

  specify "thrown failure needs to conform to :error" do
    expect {
      TeckelOperationFailOnOInput::CreateUserIncorrectFailure.call(name: "Bob", age: 23)
    }.to raise_error(Dry::Types::ConstraintError, /violates constraints/)
  end
end
