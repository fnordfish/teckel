# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

class CreateUserWithResult
  include Teckel::Operation

  result!

  input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
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
end

class CreateUserCustomResult
  include Teckel::Operation

  class MyResult
    include Teckel::Result # makes sure this can be used in a Chain

    def initialize(value, success, opts = {})
      @value, @success, @opts = value, success, opts
    end

    # implementing Teckel::Result
    def successful?
      @success
    end

    # implementing Teckel::Result
    attr_reader :value

    attr_reader :opts
  end

  result MyResult
  result_constructor ->(value, success) { MyResult.new(value, success, time: Time.now.to_i) }

  input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
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
end

class CreateUserOverwritingResult
  include Teckel::Operation

  class Result
    include Teckel::Result # makes sure this can be used in a Chain

    def initialize(value, success); end
  end
end

RSpec.describe Teckel::Operation do
  context "with build in result object" do
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

  context "using custom result" do
    specify "output" do
      result = CreateUserCustomResult.call(name: "Bob", age: 23)
      expect(result).to be_a(CreateUserCustomResult::MyResult)
      expect(result).to be_successful
      expect(result.value).to be_a(User)

      expect(result.opts).to include(time: kind_of(Integer))
    end

    specify "errors" do
      result = CreateUserCustomResult.call(name: "Bob", age: 10)
      expect(result).to be_a(CreateUserCustomResult::MyResult)
      expect(result).to be_failure
      expect(result.value).to eq(message: "Could not save User", errors: [{ age: "underage" }])

      expect(result.opts).to include(time: kind_of(Integer))
    end
  end

  context "overwriting Result" do
    it "uses the class definition" do
      expect(CreateUserOverwritingResult.result).to_not eq(Teckel::Operation::Result)
      expect(CreateUserOverwritingResult.result).to eq(CreateUserOverwritingResult::Result)
      expect(CreateUserOverwritingResult.result_constructor).to eq(CreateUserOverwritingResult::Result.method(:[]))
    end
  end
end
