# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_db'
require 'support/fake_models'

module TeckelChainAroundHookTest
  class CreateUser
    include ::Teckel::Operation

    result!

    input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
    output Types.Instance(User)
    error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

    def call(input)
      user = User.new(name: input[:name], age: input[:age])
      if user.save
        success!(user)
      else
        fail!(message: "Could not safe User", errors: user.errors)
      end
    end
  end

  class AddFriend
    include ::Teckel::Operation

    result!

    settings Struct.new(:fail_befriend)

    input Types.Instance(User)
    output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
    error  Types::Hash.schema(message: Types::String)

    def call(user)
      if settings&.fail_befriend
        fail!(message: "Did not find a friend.")
      else
        success! user: user, friend: User.new(name: "A friend", age: 42)
      end
    end
  end

  @stack = []
  def self.stack
    @stack
  end

  class Chain
    include Teckel::Chain

    around ->(chain, input) {
      result = nil
      begin
        TeckelChainAroundHookTest.stack << :before

        FakeDB.transaction do
          result = chain.call(input)
          raise FakeDB::Rollback if result.failure?
        end

        TeckelChainAroundHookTest.stack << :after
        result
      rescue FakeDB::Rollback
        result
      end
    }

    step :create, CreateUser
    step :befriend, AddFriend
  end
end

RSpec.describe Teckel::Chain do
  before { TeckelChainAroundHookTest.stack.clear }

  context "success" do
    it "result matches" do
      result = TeckelChainAroundHookTest::Chain.call(name: "Bob", age: 23)
      expect(result.success).to include(user: kind_of(User), friend: kind_of(User))
    end

    it "runs around hook" do
      TeckelChainAroundHookTest::Chain.call(name: "Bob", age: 23)
      expect(TeckelChainAroundHookTest.stack).to eq([:before, :after])
    end
  end

  context "failure" do
    it "runs around hook" do
      TeckelChainAroundHookTest::Chain.
        with(befriend: :fail).
        call(name: "Bob", age: 23)
      expect(TeckelChainAroundHookTest.stack).to eq([:before])
    end
  end
end
