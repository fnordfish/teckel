# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Waldi::Chain do
  module WaldiChainTest
    class CreateUser
      include ::Waldi::Operation::Results

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
      include ::Waldi::Operation::Results

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

      include ::Waldi::Operation::Results

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
      include Waldi::Chain

      step :create, CreateUser
      step :log, LogUser
      step :befriend, AddFriend
    end
  end

  it 'Chain input points to first step input' do
    expect(WaldiChainTest::Chain.input).to eq(WaldiChainTest::CreateUser.input)
  end

  it 'Chain output points to last steps output' do
    expect(WaldiChainTest::Chain.output).to eq(WaldiChainTest::AddFriend.output)
  end

  it 'Chain errors maps all step errors' do
    expect(WaldiChainTest::Chain.errors).to eq([
                                                 WaldiChainTest::CreateUser.error,
                                                 WaldiChainTest::AddFriend.error
                                               ])
  end

  context "success" do
    before { WaldiChainTest::AddFriend.fail_befriend = false }

    it "result matches" do
      result = WaldiChainTest::Chain.call(name: "Bob", age: 23)
      expect(result.success).to include(user: kind_of(User), friend: kind_of(User))
    end
  end

  context "failure" do
    before { WaldiChainTest::AddFriend.fail_befriend = true }

    it "returns a StepFailure for invalid input" do
      result = WaldiChainTest::Chain.call(name: "Bob", age: 0)
      expect(result).to be_a(Waldi::Chain::StepFailure)
      expect(result).to be_failure
      expect(result.step_name).to eq(:create)
      expect(result.step).to eq(WaldiChainTest::CreateUser)
    end

    it "returns a StepFailure for failed step" do
      result = WaldiChainTest::Chain.call(name: "Bob", age: 23)
      expect(result).to be_a(Waldi::Chain::StepFailure)
      expect(result).to be_failure
      expect(result.step_name).to eq(:befriend)
      expect(result.step).to eq(WaldiChainTest::AddFriend)
    end
  end
end
