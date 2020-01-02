# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Chain do
  module TeckelChainTest
    class CreateUser
      include ::Teckel::Operation::Results

      input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
      output Types.Instance(User)
      error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

      # @param [Hash<name: String, age: Integer>]
      # @return [User | Hash<message: String, errors: [Hash]>]
      def call(input)
        user = User.new(name: input[:name], age: input[:age])
        if user.safe
          success!(user)
        else
          fail!(message: "Could not safe User", errors: user.errors)
        end
      end
    end

    class LogUser
      include ::Teckel::Operation::Results

      input Types.Instance(User)
      output input

      def call(usr)
        Logger.new(File::NULL).info("User #{usr.name} created")
        usr
      end
    end

    class AddFriend
      class << self
        attr_accessor :fail_befriend
      end

      include ::Teckel::Operation::Results

      input Types.Instance(User)
      output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
      error  Types::Hash.schema(message: Types::String)

      def call(user)
        if self.class.fail_befriend
          fail!(message: "Did not find a friend.")
        else
          { user: user, friend: User.new(name: "A friend", age: 42) }
        end
      end
    end

    class Chain
      include Teckel::Chain

      step :create, CreateUser
      step :log, LogUser
      step :befriend, AddFriend
    end
  end

  it 'Chain input points to first step input' do
    expect(TeckelChainTest::Chain.input).to eq(TeckelChainTest::CreateUser.input)
  end

  it 'Chain output points to last steps output' do
    expect(TeckelChainTest::Chain.output).to eq(TeckelChainTest::AddFriend.output)
  end

  it 'Chain errors maps all step errors' do
    expect(TeckelChainTest::Chain.errors).to eq([
                                                 TeckelChainTest::CreateUser.error,
                                                 TeckelChainTest::AddFriend.error
                                               ])
  end

  context "success" do
    before { TeckelChainTest::AddFriend.fail_befriend = false }

    it "result matches" do
      result = TeckelChainTest::Chain.call(name: "Bob", age: 23)
      expect(result.success).to include(user: kind_of(User), friend: kind_of(User))
    end
  end

  context "failure" do
    before { TeckelChainTest::AddFriend.fail_befriend = true }

    it "returns a StepFailure for invalid input" do
      result = TeckelChainTest::Chain.call(name: "Bob", age: 0)
      expect(result).to be_a(Teckel::Chain::StepFailure)
      expect(result).to be_failure
      expect(result.step_name).to eq(:create)
      expect(result.step).to eq(TeckelChainTest::CreateUser)
    end

    it "returns a StepFailure for failed step" do
      result = TeckelChainTest::Chain.call(name: "Bob", age: 23)
      expect(result).to be_a(Teckel::Chain::StepFailure)
      expect(result).to be_failure
      expect(result.step_name).to eq(:befriend)
      expect(result.step).to eq(TeckelChainTest::AddFriend)
    end
  end
end
